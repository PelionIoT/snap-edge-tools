#!/usr/bin/env python3
"""Connectivity cases for one stage. Prints PASS, FAIL or BLOCKED per case, then the counts."""
import base64
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from urllib.parse import urlparse

API = os.environ['NUCLOUD_API_URL'].rstrip('/')
KEY = os.environ['NUCLOUD_API_KEY']
EXTRA = json.loads(base64.b64decode(os.environ['NUCLOUD_CONFIG_JSON']))
GATEWAY = EXTRA['internal_id']
SSH_HOST = f"{EXTRA['ssh_username']}@{EXTRA['ssh_address']}"
SSH = ['sshpass', '-e', 'ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null',
       '-o', 'LogLevel=ERROR', '-o', 'ConnectTimeout=15', SSH_HOST]
SSH_ENV = dict(os.environ, SSHPASS=EXTRA['ssh_password'])
TOOLS = '/work/snap-edge-tools'
counts = {'PASS': 0, 'FAIL': 0, 'BLOCKED': 0}


def report(result, case, detail=''):
    counts[result] += 1
    print(f'{result} {case}{": " + detail if detail else ""}', flush=True)


def check(case, ok, detail):
    report('PASS' if ok else 'FAIL', case, detail)


def get(path):
    request = urllib.request.Request(API + path, headers={'Authorization': 'Bearer ' + KEY})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def host_port(uri):
    url = urlparse(uri)
    return f'{url.hostname}:{url.port}'


def refuse_production(*hosts):
    for host in hosts:
        if host.split(':')[0].endswith('mbedcloud.com'):
            sys.exit(f'refusing production host {host}')


def sandbox(credentials):
    """Lays out a directory the way the snap does."""
    root = tempfile.mkdtemp()
    os.makedirs(f'{root}/bin')
    for name in ('daemon.sh', 'test-bootstrap.sh', 'test-lwm2m.sh'):
        shutil.copy(f'{TOOLS}/scripts/{name}', f'{root}/bin/')
    shutil.copytree(credentials, f'{root}/credentials')
    os.makedirs(f'{root}/common')
    return root


def script_env(root, hosts):
    return dict(os.environ, SNAP=root, SNAP_COMMON=f'{root}/common', SNAP_USER_COMMON=f'{root}/common', **hosts)


def run_local(script, root, hosts):
    out = subprocess.run([f'{root}/bin/{script}'], env=script_env(root, hosts), stdout=subprocess.PIPE,
                         stderr=subprocess.STDOUT, text=True, timeout=60, check=False)
    return out.stdout


def on_gateway(command, stdin=None):
    return subprocess.run(SSH + [command], env=SSH_ENV, input=stdin, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, timeout=120, check=False)


def last_line(text):
    lines = text.strip().splitlines()
    return lines[-1] if lines else '(no output)'


def container_cases(hosts):
    root = sandbox(f'{TOOLS}/credentials')
    # Bilateral: the stage's own developer certificate, from the env file, never one from a repo.
    with open(f'{root}/credentials/device_cert.pem', 'w') as cert:
        cert.write(EXTRA['edge_cert_pem'])
    with open(f'{root}/credentials/device_key.pem', 'w') as key:
        key.write(EXTRA['edge_key_pem'])
    os.chmod(f'{root}/credentials/device_key.pem', 0o600)
    for case, script, word in (('image: test-lwm2m', 'test-lwm2m.sh', 'LwM2M'),
                               ('image: test-bootstrap', 'test-bootstrap.sh', 'bootstrap')):
        out = run_local(script, root, hosts)
        check(case, f'TLS to {word} server: success' in out, last_line(out))
    shutil.rmtree(root)


def gateway_cases(hosts):
    root = sandbox(f'{TOOLS}/credentials')
    archive = subprocess.run(['tar', '-C', root, '-cz', '.'], stdout=subprocess.PIPE, check=True).stdout
    remote = on_gateway('mktemp -d /tmp/edge-tools.XXXXXX').stdout.decode().strip()
    shutil.rmtree(root)
    if not remote.startswith('/tmp/edge-tools.'):
        report('FAIL', 'gateway: ssh', remote or '(no output)')
        return
    try:
        on_gateway(f'tar -xz -C {remote}', archive)
        prefix = (f'SNAP={remote} SNAP_COMMON={remote}/common SNAP_USER_COMMON={remote}/common '
                  + ' '.join(f'{k}={v}' for k, v in hosts.items()) + ' ')
        for case, script, word in (('gateway: test-lwm2m', 'test-lwm2m.sh', 'LwM2M'),
                                   ('gateway: test-bootstrap', 'test-bootstrap.sh', 'bootstrap')):
            out = on_gateway(f'{prefix}{remote}/bin/{script}').stdout.decode()
            check(case, f'TLS to {word} server: success' in out, last_line(out))
        on_gateway(f'DAEMON_ONCE=1 {prefix}{remote}/bin/daemon.sh')
        log = on_gateway(f'cat {remote}/common/daemon.txt').stdout.decode()
        lwm2m = hosts['LWM2M_HOST'].split(':')[0]
        replies = [line for line in log.splitlines() if ' received' in line]
        check('gateway: daemon L3 ping api.snapcraft.io', ' 1 received' in replies[0], replies[0])
        if ' 1 received' in replies[1]:
            report('PASS', 'gateway: daemon L3 ping LwM2M host', replies[1])
        else:
            report('BLOCKED', 'gateway: daemon L3 ping LwM2M host', 'the stage load balancers drop ICMP')
        nc = [line for line in log.splitlines() if ' 5684' in line or ' 443' in line]
        check('gateway: daemon L4 nc', any(lwm2m in line and 'succeeded' in line for line in nc), ' | '.join(nc))
        check('gateway: daemon L7 TLS', 'TLS to LwM2M server: success' in log, 'test-lwm2m from the daemon pass')
    finally:
        on_gateway(f'rm -rf {remote}')


def main():
    refuse_production(urlparse(API).hostname)
    servers = get('/v3/server-credentials')
    hosts = {'LWM2M_HOST': host_port(servers['lwm2m']['url']),
             'BOOTSTRAP_HOST': host_port(servers['bootstrap']['url'])}
    refuse_production(*hosts.values())
    for name in ('lwm2m', 'bootstrap'):
        with open(f'{TOOLS}/credentials/{name}.pem') as pinned:
            same = pinned.read().strip() == servers[name]['certificate'].strip()
        check(f'stage: credentials/{name}.pem is the CA in /v3/server-credentials', same, hosts[f'{name.upper()}_HOST'])
    device = get(f'/v3/devices/{GATEWAY}')
    check('stage: gateway registered', device['state'] == 'registered', device['state'])
    container_cases(hosts)
    if device['state'] == 'registered':
        gateway_cases(hosts)
    else:
        report('BLOCKED', 'gateway: 5 cases', f'state {device["state"]}')
    print(f'{counts["PASS"]} passed, {counts["FAIL"]} failed, {counts["BLOCKED"]} blocked')
    sys.exit(1 if counts['FAIL'] else 0)


if __name__ == '__main__':
    main()

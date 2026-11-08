#!/usr/bin/env python3
"""SETUP_CMD: verifies the edge gateway the cases use. The gateway is a physical
machine the suite does not own, so setup only checks it: the CONFIG_JSON fact names
it, the cloud lists it as a device, and it answers on SSH. Prints one "setup:" line."""
import base64
import json
import os
import subprocess
import sys
import urllib.request


def fail(what):
    sys.exit(f'setup: {what}')


raw = os.environ.get('NUCLOUD_CONFIG_JSON', '')
if not raw:
    fail(f'{os.environ.get("NUCLOUD_STAGE", "?")} has no cloud.config_json fact naming the edge gateway (staging: ACCOUNT=edge)')
try:
    extra = json.loads(base64.b64decode(raw))
except ValueError:
    fail('cloud.config_json is not base64 JSON')
missing = [k for k in ('internal_id', 'ssh_username', 'ssh_address', 'ssh_password') if not extra.get(k)]
if missing:
    fail('cloud.config_json lacks ' + ', '.join(missing))
api = os.environ['NUCLOUD_API_URL'].rstrip('/')
request = urllib.request.Request(f'{api}/v3/devices/{extra["internal_id"]}',
                                 headers={'Authorization': 'Bearer ' + os.environ['NUCLOUD_API_KEY']})
try:
    urllib.request.urlopen(request, timeout=30).close()
except Exception as e:
    fail(f'gateway device {extra["internal_id"]} not readable in the account ({e})')
ssh = ['sshpass', '-e', 'ssh', '-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null',
       '-o', 'LogLevel=ERROR', '-o', 'ConnectTimeout=15', f'{extra["ssh_username"]}@{extra["ssh_address"]}', 'true']
if subprocess.run(ssh, env=dict(os.environ, SSHPASS=extra['ssh_password'])).returncode:
    fail(f'gateway {extra["ssh_address"]} does not answer on SSH')
print(f'setup: gateway {extra["internal_id"]} verified')

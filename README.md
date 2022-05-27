# Edge Tools

## Build Snap

Clone this repository and use the build and deploy instructions from [Snapcraft](https://snapcraft.io/docs/snapcraft-overview#heading--building-your-snap).

```
snapcraft --debug
sudo snap install edge-tools_1.0_amd64.snap --dangerous
```

## Connect Interfaces

Connect snap to the `network-observe` interface:
```
sudo snap connect edge-tools:network-observe
```

## Daemon

### Connectivity

After installation, a daemon will check for network availability every 60 seconds:
```
ping api.snapcraft.io
ping lwm2m.us-east-1.mbedcloud.com
edge-tools.test-lwm2m
```

The output is appended to:
```
/var/snap/edge-tools/common/daemon.txt
```

Note that the log file must be manually cleared to free up disk space. Log file will grow around 1 kilobyte per minute.

### Starting, stopping and removing

If you want to stop it from running, use the standard `snap` commands.

```
sudo snap stop edge-tools.daemon
```

and

```
sudo snap start edge-tools.daemon
```

to restart it.

Uninstallation can be done with:

```
sudo snap remove edge-tools
```

## Tools

### Test TLS and detect intrusive firewalls

Use `openssl` to negotiate a TLS session with bilateral certificate verification.

For connecting to either bootstrap or LwM2M server run in a command prompt:

```
edge-tools.test-bootstrap
```
or
```
edge-tools.test-lwm2m
```
The command will either return `success` or print out the handshake failure. The full `openssl` output can be found in `~/snap/edge-tools/common/`, in files `test-bootstrap.txt` and `test-lwm2m.txt`.

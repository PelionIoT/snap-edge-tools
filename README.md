# Pelion Edge Tools

## Build Snap

Clone this repository and use the build and deploy instructions from [Snapcraft](https://snapcraft.io/docs/snapcraft-overview#heading--building-your-snap).

## Tools

### Test TLS and detect intrusive firewalls

Use `openssl` to negotiate a TLS session with bilateral certificate verification. 
For connecting to either Pelion's bootstrap or LwM2M server run in a command prompt:

```
> pelion-edge-tools.test-bootstrap
```
or 
```
> pelion-edge-tools.test-lwm2m
```
The command will either return `success` or print out the handshake failure. If the command is executed from a directory with write access, the full `openssl` output can be found in `test-bootstrap.txt` and `test-lwm2m.txt`. 


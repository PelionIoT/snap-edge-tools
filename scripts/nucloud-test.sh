#!/bin/sh
# Runs the connectivity scripts against the stage, in this image and on the gateway
# named in NUCLOUD_CONFIG_JSON. Nothing is installed on the gateway: the scripts and
# the stage's public CAs go to a temporary directory there, which this script removes.
# The calls are GET /v3 reads and TLS handshakes that send no CoAP.
set -eu
: "${NUCLOUD_API_URL:?make test sets it}" "${NUCLOUD_API_KEY:?make test sets it}"
: "${NUCLOUD_CONFIG_JSON:?run with ACCOUNT=edge: the env file names the gateway}"
exec python3 scripts/nucloud_cases.py

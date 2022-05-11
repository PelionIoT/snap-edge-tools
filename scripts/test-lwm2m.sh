#!/bin/sh

# exit on error
set -e

# use openssl to connect to lwm2m server using device credentials
# store output in $SNAP_USER_COMMON/test-lwm2m.txt
echo "Write openssl output to $SNAP_USER_COMMON/test-lwm2m.txt"
echo | openssl s_client -CAfile $SNAP/credentials/lwm2m.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect lwm2m.us-east-1.mbedcloud.com:5684 2>$SNAP_USER_COMMON/test-lwm2m.txt > $SNAP_USER_COMMON/test-lwm2m.txt
RESULT=`grep 'Verify return code' $SNAP_USER_COMMON/test-lwm2m.txt`

# get openssl return code and print result
CODE=`echo $RESULT | awk -F' ' '{print $4}'`

if [ $CODE = 0 ]; then
    echo "TLS to LwM2M server: success"
else
    echo "TLS to LwM2M server:"
    echo $RESULT
fi

#!/bin/sh

# use openssl to connect to the LwM2M server, with bilateral verification when
# device_cert.pem and device_key.pem sit in CREDENTIALS
# store output in $SNAP_USER_COMMON/test-lwm2m.txt
LWM2M_HOST=${LWM2M_HOST:-lwm2m.izuma.io:5684}
CREDENTIALS=${CREDENTIALS:-$SNAP/credentials}
if [ -f "$CREDENTIALS/device_cert.pem" ]; then
    CLIENT="-key $CREDENTIALS/device_key.pem -cert $CREDENTIALS/device_cert.pem"
fi

echo "Write openssl output to $SNAP_USER_COMMON/test-lwm2m.txt"
echo | openssl s_client -CAfile $CREDENTIALS/lwm2m.pem $CLIENT -connect $LWM2M_HOST 2>$SNAP_USER_COMMON/test-lwm2m.txt > $SNAP_USER_COMMON/test-lwm2m.txt

# get openssl return code
RESULT=`grep 'Verify return code' $SNAP_USER_COMMON/test-lwm2m.txt`

if [ -z "$RESULT" ]; then
    echo "openssl failed with:"
    cat $SNAP_USER_COMMON/test-lwm2m.txt
    exit
fi

# print result
CODE=`echo $RESULT | awk -F' ' '{print $4}'`

if [ $CODE = 0 ]; then
    echo "TLS to LwM2M server: success"
else
    echo "TLS to LwM2M server:"
    echo $RESULT
fi

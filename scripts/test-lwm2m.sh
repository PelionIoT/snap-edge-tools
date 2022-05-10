#!/bin/sh

# check if user has write permission to current folder
RESULT=`stat -c '%a' .`
RESULT=`expr $RESULT / 400`

# use openssl to connect to lwm2m server using device credentials
if [ $RESULT -ge 1 ]; then

    # store output in test-lwm2m.txt
    echo "Write openssl output to test-lwm2m.txt"
    echo | openssl s_client -CAfile $SNAP/credentials/lwm2m.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect lwm2m.us-east-1.mbedcloud.com:5684 2>test-lwm2m.txt > test-lwm2m.txt
    RESULT=`grep 'Verify return code' test-lwm2m.txt`
else
    RESULT=`echo | openssl s_client -CAfile $SNAP/credentials/lwm2m.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect lwm2m.us-east-1.mbedcloud.com:5684 2>/dev/null | grep 'Verify return code'`
fi

# get openssl return code and print result
CODE=`echo $RESULT | awk -F' ' '{print $4}'`

if [ $CODE = 0 ]; then
    echo "TLS to LwM2M server: success"
else
    echo "TLS to LwM2M server:"
    echo $RESULT
fi

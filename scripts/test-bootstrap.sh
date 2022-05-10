#!/bin/sh

# check if user has write permission to current folder
RESULT=`stat -c '%a' .`
RESULT=`expr $RESULT / 400`

# use openssl to connect to bootstrap server using device credentials
if [ $RESULT -ge 1 ]; then

    # store output in test-bootstrap.txt
    echo "Write openssl output to test-bootstrap.txt"
    echo | openssl s_client -CAfile $SNAP/credentials/bootstrap.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect tcp-bootstrap.us-east-1.mbedcloud.com:5684 2>test-bootstrap.txt > test-bootstrap.txt
    RESULT=`grep 'Verify return code' test-bootstrap.txt`
else
    RESULT=`echo | openssl s_client -CAfile $SNAP/credentials/bootstrap.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect tcp-bootstrap.us-east-1.mbedcloud.com:5684 2>/dev/null | grep 'Verify return code'`
fi

# get openssl return code and print result
CODE=`echo $RESULT | awk -F' ' '{print $4}'`

if [ $CODE = 0 ]; then
    echo "TLS to bootstrap server: success"
else
    echo "TLS to bootstrap server:"
    echo $RESULT
fi

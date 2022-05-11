#!/bin/sh

# use openssl to connect to bootstrap server using device credentials
# store output in $SNAP_USER_COMMON/test-bootstrap.txt
echo "Write openssl output to $SNAP_USER_COMMON/test-bootstrap.txt"
echo | openssl s_client -CAfile $SNAP/credentials/bootstrap.pem -key $SNAP/credentials/device01_key.pem -cert $SNAP/credentials/device01_cert.pem -connect tcp-bootstrap.us-east-1.mbedcloud.com:5684 2>$SNAP_USER_COMMON/test-bootstrap.txt > $SNAP_USER_COMMON/test-bootstrap.txt

# get openssl return code
RESULT=`grep 'Verify return code' $SNAP_USER_COMMON/test-bootstrap.txt`

if [ -z "$RESULT" ]; then
    echo "openssl failed with:"
    cat $SNAP_USER_COMMON/test-bootstrap.txt
    exit
fi

# print result
CODE=`echo $RESULT | awk -F' ' '{print $4}'`

if [ $CODE = 0 ]; then
    echo "TLS to bootstrap server: success"
else
    echo "TLS to bootstrap server:"
    echo $RESULT
fi

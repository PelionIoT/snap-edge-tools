#!/bin/sh

# use openssl to connect to the bootstrap server, with bilateral verification when
# device_cert.pem and device_key.pem sit in CREDENTIALS
# store output in $SNAP_USER_COMMON/test-bootstrap.txt
BOOTSTRAP_HOST=${BOOTSTRAP_HOST:-bootstrap.izuma.io:5684}
CREDENTIALS=${CREDENTIALS:-$SNAP/credentials}
if [ -f "$CREDENTIALS/device_cert.pem" ]; then
    CLIENT="-key $CREDENTIALS/device_key.pem -cert $CREDENTIALS/device_cert.pem"
fi

echo "Write openssl output to $SNAP_USER_COMMON/test-bootstrap.txt"
echo | openssl s_client -CAfile $CREDENTIALS/bootstrap.pem $CLIENT -connect $BOOTSTRAP_HOST 2>$SNAP_USER_COMMON/test-bootstrap.txt > $SNAP_USER_COMMON/test-bootstrap.txt

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

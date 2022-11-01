#!/bin/sh

while true
do
    # Put timestamp in log
    date >> $SNAP_COMMON/daemon.txt

    # Test network L3
    /bin/ping -4 -q -c 1 api.snapcraft.io >> $SNAP_COMMON/daemon.txt 2>&1
    /bin/ping -4 -q -c 1 lwm2m.us-east-1.mbedcloud.com >> $SNAP_COMMON/daemon.txt 2>&1

    # Test network L4
    /bin/nc -v -w 1 api.snapcraft.io 443 >> $SNAP_COMMON/daemon.txt 2>&1
    /bin/nc -v -w 1 lwm2m.us-east-1.mbedcloud.com 443 >> $SNAP_COMMON/daemon.txt 2>&1

    # Test network L7
    $SNAP/bin/test-lwm2m.sh >> $SNAP_COMMON/daemon.txt 2>&1
    echo "==========8<----------" >> $SNAP_COMMON/daemon.txt

    sleep 60
done

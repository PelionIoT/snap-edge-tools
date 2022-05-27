#!/bin/sh

while true
do
    date >> $SNAP_COMMON/daemon.txt
    /bin/ping -4 -q -c 1 api.snapcraft.io >> $SNAP_COMMON/daemon.txt
    /bin/ping -4 -q -c 1 lwm2m.us-east-1.mbedcloud.com >> $SNAP_COMMON/daemon.txt
    $SNAP/bin/test-lwm2m.sh >> $SNAP_COMMON/daemon.txt
    echo "==========8<----------" >> $SNAP_COMMON/daemon.txt

    sleep 60
done

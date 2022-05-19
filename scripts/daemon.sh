#!/bin/sh

while true
do
    date >> $SNAP_COMMON/daemon.txt
    /bin/ping -q -c 1 lwm2m.us-east-1.mbedcloud.com >> $SNAP_COMMON/daemon.txt
    /snap/pelion-edge-tools/current/bin/test-lwm2m.sh >> $SNAP_COMMON/daemon.txt
    echo "==========8<----------" >> $SNAP_COMMON/daemon.txt

    sleep 60
done

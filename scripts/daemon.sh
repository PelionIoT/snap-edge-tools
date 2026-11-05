#!/bin/sh

# DAEMON_ONCE=1 runs one pass and exits.
LWM2M_NAME=${LWM2M_HOST:-lwm2m.izuma.io:5684}
LWM2M_NAME=${LWM2M_NAME%:*}

while true
do
    # Put timestamp in log
    date >> $SNAP_COMMON/daemon.txt

    # Test network L3
    /bin/ping -4 -q -c 1 api.snapcraft.io >> $SNAP_COMMON/daemon.txt 2>&1
    /bin/ping -4 -q -c 1 $LWM2M_NAME >> $SNAP_COMMON/daemon.txt 2>&1

    # Test network L4
    /bin/nc -v -w 1 api.snapcraft.io 443 >> $SNAP_COMMON/daemon.txt 2>&1 </dev/null
    /bin/nc -v -w 1 $LWM2M_NAME 5684 >> $SNAP_COMMON/daemon.txt 2>&1 </dev/null

    # Test network L7
    $SNAP/bin/test-lwm2m.sh >> $SNAP_COMMON/daemon.txt 2>&1
    echo "==========8<----------" >> $SNAP_COMMON/daemon.txt

    [ -n "${DAEMON_ONCE:-}" ] && break
    sleep 60
done

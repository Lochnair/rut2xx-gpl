#!/bin/sh

#
# Indicate reset button pressed time
#
# (c) 2014 Teltonika
SLEEP_TIME=1000000
LEDBAR="/usr/sbin/ledbar.sh"

[ ! -z $1 ] && SLEEP_TIME=$1

$LEDBAR
for i in 0 1 2 3 4
do
	usleep $SLEEP_TIME
	$LEDBAR $i
done

exit 0


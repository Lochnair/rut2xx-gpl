#!/bin/sh

retry="3"
count="0"

while [ true ]; do
	cgreg=`gsmctl -n -A AT+CGREG?| awk -F ',' '{print $2}'`

	if [ "$cgreg" = "5" ] || [ "$cgreg" = "1" ]; then
		count="0"
	fi

	if [ $count -gt $retry ]; then
		logger -t "operchk" "connection lost, restarting operctl"
		sleep 20
		/etc/init.d/operctl restart
		exit
	fi

	count=$((count+1))
	sleep 20
done

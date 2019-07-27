#!/bin/sh


KEEP_MOBILE="keep_mobile"
DOWNLOAD="-k"
FW_FILE_RMS="/tmp/firmware"
FW_FILE="/tmp/firmware.img"
BACKUP_SECTIONS=""
BACKUP_CONFIGS=""
SYSUPGRADE_OPTS=""
UPGRADE_CMD=""


log_event() {
	local event_type=$1
	local event_text=$2
	/usr/bin/eventslog -i -t EVENTS -n "$event_type" -e "$event_text"
}

fix_date() {
	local dateold=`date +%s`
	local datenew=$((dateold + 125))
	date +%s -s @"$datenew"
	touch /etc/init.d/luci_fixtime
	log_event "Reboot" "Request after FW upgrade"
	uci set system.device_info.reboot=1
	uci commit system
}

if [ -e "$FW_FILE_RMS" ] && [ -e "$FW_FILE" ]; then
	if [ "$FW_FILE" -nt "$FW_FILE_RMS" ]; then
		rm -f $FW_FILE_RMS
	fi
fi

if [ -e "$FW_FILE_RMS" ]; then
	mv $FW_FILE_RMS $FW_FILE
fi

if [ ! -e "$FW_FILE" ]; then
	echo "$FW_FILE not found!"
	log_event "FW" "$FW_FILE not found!"
	exit 1
fi

while [ $# -gt 0 ]; do
	case "$1" in
		"$DOWNLOAD")
			SYSUPGRADE_OPTS="-k"
			;;
	esac
	shift
done


if [ ! -z "$SYSUPGRADE_OPTS" ]; then
	log_event "FW" "Upgrade from file"
else
	log_event "FW" "Upgrade from server"
fi


fix_date

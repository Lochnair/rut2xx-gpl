#!/bin/sh


KEEP_MOBILE="keep_mobile"
DOWNLOAD="download"
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
		"$KEEP_MOBILE")
			BACKUP_SECTIONS="$BACKUP_SECTIONS"" network.ppp simcard.sim1"
			BACKUP_CONFIGS="$BACKUP_CONFIGS"" simcard data_limit reregister"
			;;
		"$DOWNLOAD")
			SYSUPGRADE_OPTS="-k"
			;;
	esac
	shift
done


if [ -z "$SYSUPGRADE_OPTS" ]; then
	log_event "FW" "Upgrade from file"
else
	log_event "FW" "Upgrade from server"
fi

if [ -z "$BACKUP_CONFIGS" ]; then
	SYSUPGRADE_OPTS="-n ""$SYSUPGRADE_OPTS"
fi

SYSUPGRADE_OPTS="$SYSUPGRADE_OPTS"" $FW_FILE"


UPGRADE_CMD="killall dropbear uhttpd; sleep 1; "

if [ ! -z "$BACKUP_SECTIONS" ]; then
	UPGRADE_CMD="$UPGRADE_CMD"" /sbin/keep_settings_new.sh backup ""$BACKUP_SECTIONS"";"
fi

if [ ! -z "$BACKUP_CONFIGS" ]; then
	UPGRADE_CMD="$UPGRADE_CMD"" /sbin/leave_config_new.sh ""$BACKUP_CONFIGS""; mkdir -p /etc/uci-defaults; touch /etc/uci-defaults/99_touch-firstboot;"
fi

UPGRADE_CMD="$UPGRADE_CMD"" /sbin/sysupgrade ""$SYSUPGRADE_OPTS"


echo "FINAL FIRMWARE UPGRADE COMMAND: '$UPGRADE_CMD'"

<<DEBUG_TEST
sleep 3
echo -n "UPGRADING IN 3"
sleep 1
echo -n " 2"
sleep 1
echo -n " 1"
sleep 1
echo ". UPGRADING !!!"
DEBUG_TEST

fix_date

eval "($UPGRADE_CMD) &"

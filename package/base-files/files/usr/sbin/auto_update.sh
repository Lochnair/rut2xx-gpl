#!/bin/sh
# Copyright (C) 2014 Teltonika

. /lib/teltonika-functions.sh

CONFIG_GET="uci -q get auto_update.auto_update"
CONFIG_SET="uci -q set auto_update.auto_update"
REMOTE_VERSION_FILE="/tmp/version_remote"
CRONTAB_FILE="/etc/crontabs/root"
CA_FILE="/etc/cacert.pem"
PRE_SCRIPT_PATH="/tmp/pre_update_script.sh"
POST_SCRIPT_PATH="/tmp/post_update_script.sh"
FW_FILE_PATH="/tmp/firmware.img"
FREE_SPACE_LIMIT=1024000

EXIT_BAD_USAGE=1
EXIT_DISABLED=2
EXIT_MOBILE_DATA=3
EXIT_BAD_SERIAL=4
EXIT_BAD_URL=5
EXIT_CURL_ERROR=6
EXIT_BAD_KEEP_SETTINGS_STRING=7
EXIT_SERVER_ERROR=8
EXIT_FW_FILE_NOT_FOUND=9
EXIT_BAD_FILE_SIZE_STRING=10
EXIT_BAD_FREE_RAM_STRING=11
EXIT_NOT_ENOUGH_RAM=12
EXIT_BAD_CONFIG=13
EXIT_BAD_MAC=14
EXIT_CURL_CACERT=15

PrintUsage() {
	echo "Usage: `basename $0` [mode (init, check, forced_check, get), <keep settings string>]"
	echo "init - perform first start init (used by service init script)"
	echo "check - check for FW update"
	echo "forced_check - ignore 'enable' tag and check for FW update"
	echo "get - download new FW from server if it exists"
	echo "<keep settings string> - used only in 'get' mode"

	exit $EXIT_BAD_USAGE
}

if [ $# -gt 0 ] && [ $# -lt 3 ]; then
	if [ $# -eq 1 ] && [ "$1" == "get" ]; then
		PrintUsage
	fi
	if [ $# -eq 2 ] && [ "$1" != "get" ]; then
		PrintUsage
	fi
else
	PrintUsage
fi

keep_settings="$2"

SubStringPos () {
	local string
	local substring
	local index
	local tmp

	string="$1"
	substring="$2"
	index="-1"

	case "$string" in
		*$substring*)
			tmp=${string%%$substring*}
			index=${#tmp}
			;;
	esac

	echo "$index"
}

IsNumber() {
	local string
	local result

	string="$1"
	result=1

	case "$string" in
		''|*[!0-9]*)
			result=0
			;;
	esac

	return $result
}

CheckEnabledFlag() {
	local enabled
	local found

	enabled=$($CONFIG_GET.enable)

	if [ "$enabled" != "1" ]; then
		found=$(grep -q "/usr/sbin/auto_update.sh" "$CRONTAB_FILE"; echo $?)
		if [ "$found" -eq 0 ]; then
			sed -i "\/usr\/sbin\/auto_update.sh/d" "$CRONTAB_FILE"
			found=$(ps | grep -q "[*c]rond"; echo $?)
			if [ "$found" -eq 0 ]; then
				/etc/init.d/cron restart&
			fi
		fi

		exit $EXIT_DISABLED
	fi
}

Init() {
	local mode

	mode=$($CONFIG_GET.mode)

	if [ "$mode" == "on_start" ]; then
		InitOnStart
	elif [ "$mode" == "on_login" ]; then
		InitOnLogin
	elif [ "$mode" == "periodic" ]; then
		InitPeriodic
	else
		exit $EXIT_BAD_CONFIG
	fi
}

InitOnStart() {
	local found

	if [ -f "$CRONTAB_FILE" ]; then
		sed -i "\/usr\/sbin\/auto_update.sh/d" "$CRONTAB_FILE"
	fi

	found=$(ps | grep -q "[*c]rond"; echo $?)
	if [ "$found" -eq 0 ]; then
		/etc/init.d/cron restart&
	fi

	tlt_wait_for_wan auto-update > /dev/null
	CheckForUpdate
}

InitOnLogin() {
	local found
	local last_session
	local curr_session

	if [ -f "$CRONTAB_FILE" ]; then
		sed -i "\/usr\/sbin\/auto_update.sh/d" "$CRONTAB_FILE"
	fi

	found=$(ps | grep -q "[*c]rond"; echo $?)
	if [ "$found" -eq 0 ]; then
		/etc/init.d/cron restart&
	fi

	while [ true ]; do
		curr_session="$(ls -A /tmp/luci-sessions)"

		if [ -n "$curr_session" ]; then
			if [ "$last_session" != "$curr_session" ]; then
				last_session=$curr_session
				CheckForUpdate
			fi
		else
			last_session=$curr_session
		fi

		sleep 5
	done
}

InitPeriodic() {
	local found
	local hours
	local minutes
	local days
	local temp

	if [ -f "$CRONTAB_FILE" ]; then
		sed -i "\/usr\/sbin\/auto_update.sh/d" "$CRONTAB_FILE"
	fi

	hours=$($CONFIG_GET.hours)
	minutes=$($CONFIG_GET.minutes)
	days=$($CONFIG_GET.day)
	temp=${days// /""}

	if [ "$hours" != "" ] && [ "$minutes" != "" ] && [ "$temp" != "" ]; then
		IsNumber "$hours"
		if [ $? -eq 0 ]; then
			exit $EXIT_BAD_CONFIG
		fi

		IsNumber "$minutes"
		if [ $? -eq 0 ]; then
			exit $EXIT_BAD_CONFIG
		fi

		IsNumber "$temp"
		if [ $? -eq 0 ]; then
			exit $EXIT_BAD_CONFIG
		fi
	else
		exit $EXIT_BAD_CONFIG
	fi

	days=${days// /,}
	echo "$minutes $hours * * $days /usr/sbin/auto_update.sh check" >> "$CRONTAB_FILE"
	found=$(ps | grep -q "[*c]rond"; echo $?)
	if [ "$found" -eq 0 ]; then
		/etc/init.d/cron restart&
	fi
}

CheckForUpdate() {
	local forced_check
	local not_mobile
	local wan_ifname
	local server_url
	local username
	local password
	local serial
	local mac
	local model
	local temp
	local auth_string
	local query_string
	local fw_version
	local fw_version_string

	forced_check="$1"

	if [ "$forced_check" != "forced" ]; then
		not_mobile=$($CONFIG_GET.not_mobile)

		if [ "$not_mobile" -eq 1 ]; then
			wan_ifname=$(uci -q get network.wan.ifname)

			temp=0
			for name in `echo "$wan_ifname"`; do
				case "$name" in
					3g-ppp)
						temp=1
						;;
					eth2)
						temp=1
						;;
				esac
			done

			if [ "$temp" -eq 1 ]; then
				exit $EXIT_MOBILE_DATA
			fi
		fi
	fi

	server_url=$($CONFIG_GET.server_url)
	if [ "$server_url" == "" ]; then
		exit $EXIT_BAD_URL
	fi

    if [ "$(SubStringPos "$server_url" "https://")" != "-1" ]; then
        if [ "$(SubStringPos "$server_url" "http://")" != "-1" ]; then
			server_url="http://$server_url"
		fi
	fi

	fw_version=""
	if [ -f "/etc/version" ]; then
		fw_version=$(cat /etc/version)
	fi

	if [ "$fw_version" != "" ]; then
		fw_version_string="&fw_version=$fw_version"
	fi

	username=$($CONFIG_GET.userName)
	password=$($CONFIG_GET.password)

	auth_string=""
	if [ "$username" != "" ] && [ "$password" != "" ]; then
		auth_string="&username=$username&password=$password"
	fi

	serial=`mnf_info sn`
	IsNumber "$serial"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_SERIAL
	fi

	mac=`mnf_info mac`
	if [ ${#mac} -ne 12 ]; then
		exit $EXIT_BAD_MAC
	fi

	model=`mnf_info name`

	query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=check$fw_version_string$auth_string"
	temporary_path="/tmp/auto_update_check"
	http_code=$(curl --connect-timeout 10 --silent --output $temporary_path --write-out "%{http_code}" --cacert "$CA_FILE" -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
	curl_exit=$?

	if [ $http_code -ne 200 ]; then
		rm -f $temporary_path
		exit $EXIT_SERVER_ERROR
	fi

	if [ $curl_exit -ne 0 ]; then
		rm -f $temporary_path
		if [ $curl_exit -eq 60 ]; then
			exit $EXIT_CURL_CACERT
		fi
		exit $EXIT_CURL_ERROR
	fi

	temp="$(cat $temporary_path)"

	if [ "$temp" != "" ]; then
		echo "$temp" > $REMOTE_VERSION_FILE
	else
		# temp is empty, meaning local firmware is up to date
		rm -f $REMOTE_VERSION_FILE
	fi

	rm -f $temporary_path

	query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=get_url&keep_settings=$keep_settings$fw_version_string$auth_string"
	temporary_path="/tmp/auto_update_url"
	http_code=$(curl --connect-timeout 10 --silent --output $temporary_path --write-out "%{http_code}" --cacert "$CA_FILE" -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
	curl_exit=$?

	if [ $http_code -ne 200 ]; then
		rm -f $temporary_path
		exit $EXIT_SERVER_ERROR
	fi

	if [ $curl_exit -ne 0 ]; then
		rm -f $temporary_path
		if [ $curl_exit -eq 60 ]; then
			exit $EXIT_CURL_CACERT
		fi
		exit $EXIT_CURL_ERROR
	fi

	temp="$(cat $temporary_path)"
	rm -f $temporary_path

	pre_cmd_size=$(echo $temp | cut -f 1 -d \|)
	fw_size=$(echo $temp | cut -f 2 -d \|)
	post_cmd_size=$(echo $temp | cut -f 3 -d \|)

	echo "fw_size: $fw_size" >> /tmp/logger.log

	IsNumber "$pre_cmd_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	IsNumber "$fw_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	IsNumber "$post_cmd_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	if [ "$fw_size" = "0" ]; then
		exit $EXIT_FW_FILE_NOT_FOUND
	fi
}

GetUpdate() {
	local not_mobile
	local wan_ifname
	local server_url
	local username
	local password
	local serial
	local mac
	local model
	local temp
	local auth_string
	local query_string
	local fw_version
	local fw_version_string
	local keep_settings
	local pre_cmd_size
	local fw_size
	local post_cmd_size
	local size

	keep_settings="$1"

	rm "$PRE_SCRIPT_PATH" > /dev/null 2>&1
	rm "$POST_SCRIPT_PATH" > /dev/null 2>&1
	rm "$FW_FILE_PATH" > /dev/null 2>&1
	$CONFIG_SET.pre_fw_post=""
	uci commit auto_update

	IsNumber "$keep_settings"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_KEEP_SETTINGS_STRING
	fi

	not_mobile=$($CONFIG_GET.not_mobile)

	if [ "$not_mobile" -eq 1 ]; then
		wan_ifname=$(uci -q get network.wan.ifname)

		temp=0
		case "$wan_ifname" in
			*3g-ppp*)
				temp=1
				;;
			*eth2*)
				temp=1
				;;
		esac

		if [ "$temp" -eq 1 ]; then
			exit $EXIT_MOBILE_DATA
		fi
	fi

	server_url=$($CONFIG_GET.server_url)
	if [ "$server_url" == "" ]; then
		exit $EXIT_BAD_URL
	fi

    if [ "$(SubStringPos "$server_url" "https://")" != "-1" ]; then
        if [ "$(SubStringPos "$server_url" "http://")" != "-1" ]; then
			server_url="http://$server_url"
		fi
	fi

	fw_version=""
	if [ -f "/etc/version" ]; then
		fw_version=$(cat /etc/version)
	fi

	if [ "$fw_version" != "" ]; then
		fw_version_string="&fw_version=$fw_version"
	fi

	username=$($CONFIG_GET.userName)
	password=$($CONFIG_GET.password)

	auth_string=""
	if [ "$username" != "" ] && [ "$password" != "" ]; then
		auth_string="&username=$username&password=$password"
	fi

	serial=`mnf_info sn`
	IsNumber "$serial"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_SERIAL
	fi

	mac=`mnf_info mac`
	if [ ${#mac} -ne 12 ]; then
		exit $EXIT_BAD_MAC
	fi

	model=`mnf_info name`

	query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=get_url&keep_settings=$keep_settings$fw_version_string$auth_string"
	temporary_path="/tmp/auto_update_url"
	http_code=$(curl --connect-timeout 10 --silent --output $temporary_path --write-out "%{http_code}" --cacert "$CA_FILE" -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
	curl_exit=$?

	if [ $http_code -ne 200 ]; then
		rm -f $temporary_path
		exit $EXIT_SERVER_ERROR
	fi

	if [ $curl_exit -ne 0 ]; then
		rm -f $temporary_path
		if [ $curl_exit -eq 60 ]; then
			exit $EXIT_CURL_CACERT
		fi
		exit $EXIT_CURL_ERROR
	fi

	temp="$(cat $temporary_path)"
	rm -f $temporary_path

	pre_cmd_size=$(echo $temp | cut -f 1 -d \|)
	fw_size=$(echo $temp | cut -f 2 -d \|)
	post_cmd_size=$(echo $temp | cut -f 3 -d \|)

	IsNumber "$pre_cmd_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	IsNumber "$fw_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	IsNumber "$post_cmd_size"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FILE_SIZE_STRING
	fi

	if [ "$fw_size" = "0" ]; then
		exit $EXIT_FW_FILE_NOT_FOUND
	fi

	temp=$(df -k /tmp | awk '/[0-9]%/{print $(NF-2)}')
	IsNumber "$temp"
	if [ $? -eq 0 ]; then
		exit $EXIT_BAD_FREE_RAM_STRING
	fi

	temp=$((temp * 1024))
	size=$((pre_cmd_size + fw_size + post_cmd_size))
	temp=$((temp - size))
	if [ "$temp" -lt $FREE_SPACE_LIMIT ]; then
		exit $EXIT_NOT_ENOUGH_RAM
	fi

	if [ "$pre_cmd_size" != "0" ]; then
		query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=get_file&file=pre_cmd&keep_settings=$keep_settings$fw_version_string$auth_string"
		http_code=$(curl --connect-timeout 10 --silent --output "$PRE_SCRIPT_PATH" --write-out "%{http_code}" --cacert "$CA_FILE" -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
		curl_exit=$?
		if [ $http_code -ne 200 ]; then
			rm -f $PRE_SCRIPT_PATH
			exit $EXIT_SERVER_ERROR
		fi

		if [ $curl_exit -ne 0 ]; then
			rm -f $PRE_SCRIPT_PATH
			if [ $curl_exit -eq 60 ]; then
				exit $EXIT_CURL_CACERT
			fi
			exit $EXIT_CURL_ERROR
		fi
	fi

	if [ "$post_cmd_size" != "0" ]; then
		query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=get_file&file=post_cmd&keep_settings=$keep_settings$fw_version_string$auth_string"
		http_code=$(curl --connect-timeout 10 --silent --output "$POST_SCRIPT_PATH"  --write-out "%{http_code}" --cacert "$CA_FILE"  -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
		curl_exit=$?
		if [ $http_code -ne 200 ]; then
			rm -f $POST_SCRIPT_PATH
			exit $EXIT_SERVER_ERROR
		fi

		if [ $curl_exit -ne 0 ]; then
			rm -f $POST_SCRIPT_PATH
			if [ $curl_exit -eq 60 ]; then
				exit $EXIT_CURL_CACERT
			fi
			exit $EXIT_CURL_ERROR
		fi
	fi

	$CONFIG_SET.file_size="$fw_size"
	uci commit auto_update
	query_string="?type=firmware&serial=$serial&mac=$mac&model=$model&action=get_file&file=fw&keep_settings=$keep_settings$fw_version_string$auth_string"
	http_code=$(curl --connect-timeout 10 --silent --output "$FW_FILE_PATH" --write-out "%{http_code}" --cacert "$CA_FILE" -A "RUT9xx ($serial,$mac) FW update service" "$server_url$query_string" 2>&1)
	curl_exit=$?
	if [ $http_code -ne 200 ]; then
		rm -f $FW_FILE_PATH
		exit $EXIT_SERVER_ERROR
	fi

	if [ $curl_exit -ne 0 ]; then
		rm -f $FW_FILE_PATH
		if [ $curl_exit -eq 60 ]; then
			exit $EXIT_CURL_CACERT
		fi
		exit $EXIT_CURL_ERROR
	fi
	$CONFIG_SET.pre="$pre_cmd_size"
	$CONFIG_SET.post="$post_cmd_size"
	uci commit auto_update
}

case "$1" in
	init)
		CheckEnabledFlag
		Init
		;;
	check)
		CheckEnabledFlag
		CheckForUpdate
		;;
	forced_check)
		CheckForUpdate "forced"
		;;
	get)
		GetUpdate "$keep_settings"
		;;
	*)
		PrintUsage
		;;
esac

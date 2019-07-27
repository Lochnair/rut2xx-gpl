#!/bin/sh
[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

#let netifd know which parameters does this protocol have. Later params are parsed with json_get_var/json_get_vars
#no_device=1 is used because carrier and operstate is not working for EC25 wwan0 iface,
#if no_device=0, netifd won't even try to start our profile until the device is already up. It waits for operstate=up and carrier=1, then starts the profile.
proto_qmi2_init_config() {
	proto_config_add_string "device:device"
	proto_config_add_string apn
	proto_config_add_string auth_mode
	proto_config_add_string username
	proto_config_add_string password
	proto_config_add_string method
	proto_config_add_string enabled
	proto_config_add_string roaming
	proto_config_add_string pdptype
	proto_config_add_string mtu
	proto_config_add_defaults
	no_device=1
	#if available=0, after every 'proto_set_available "$interface" 0'(swithcing between ppp/qmi or wan, unsuccessful connection attempt), there should be call 'proto_set_available "$interface" 1'.
	#Available=1 automatically sets 'proto_set_available "$interface" 1' if proto is changed in network.ppp.proto
	available=1
}

#Set up connection.
proto_qmi2_setup() {

	local interface="$1"
	local br=0
	local			apn device username password auth_mode roaming method pdptype mtu ip4table $PROTO_DEFAULT_OPTIONS
	json_get_vars	apn device username password auth_mode roaming method pdptype mtu ip4table $PROTO_DEFAULT_OPTIONS

	echo "setup: $1"

	[ -z "$roaming" ] && roaming=0

	if [ "$pdptype" = "1" ]; then
		pdptype=""
	else
		pdptype="-6"
	fi

	if [ -z "$auth_mode" -o "$auth_mode" = "none" ]; then
		auth_mode=0
	elif [ "$auth_mode" = "pap" ]; then
		auth_mode="1"
	elif [ "$auth_mode" = "chap" ]; then
		auth_mode="2"
	fi

	#Checking if interface is enabled and if not disabling it
	json_get_var enabled enabled
	if [ "$enabled" != "1" ] && [ ! -f "/tmp/mobileon" ]; then
		ifdown ppp
		return 0
	fi

	#Checking modem existance and operation
	[ -n "$device" ] || {
		echo "No control device specified"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	[ -c "$device" ] || {
		echo "The specified control device does not exist"
		proto_notify_error "$interface" NO_DEVICE
		proto_set_available "$interface" 0
		return 1
	}

	devname="$(basename "$device")"
	devpath="$(readlink -f /sys/class/usbmisc/$devname/device/)"
	ifname="$( ls "$devpath"/net )"
	[ -n "$ifname" ] || {
		echo "The interface could not be found."
		proto_notify_error "$interface" NO_IFACE
		proto_set_available "$interface" 0
		return 1
	}

	if [ "$roaming" = "0" ]; then
		gsmctl -A 'AT+QCFG="roamservice",255,1'
	else
		gsmctl -A 'AT+QCFG="roamservice",1,1'
	fi
	#~ Short sleep for at command
	sleep 1

	local pdptype_curr=`cat /proc/sys/net/ipv6/conf/wwan0/disable_ipv6`
	if [ "$pdptype" == "1" ]; then
		if [ "$pdptype_curr" == "0" ]; then
			sysctl -e -w net.ipv6.conf.wwan0.disable_ipv6=1
		fi
	else
		if [ "$pdptype_curr" == "1" ]; then
			sysctl -e -w net.ipv6.conf.wwan0.disable_ipv6=0
		fi
	fi

	# workaround to set IPv4 only instead of IPv6...
	/usr/sbin/gsmctl -A 'at+cgdcont=1,"IP"'

	#workaround for this module fw version due to APN set bug left by Quectel
	modem_version=`/usr/sbin/gsmctl -y`
	if [ "$modem_version" == "EC25AFAR05A04M4G" ] || [ "$modem_version" == "EC20EQAR02A11E2G" ]; then
		# SET CONTEXTS
		/usr/sbin/gsmctl -A 'AT+CGDCONT=1,"IP",""'
		/usr/sbin/gsmctl -A 'AT+CGDCONT=2'
		/usr/sbin/gsmctl -A "AT+CGDCONT=3,\"IP\",\"$apn\""
		/usr/sbin/gsmctl -A 'AT+CGDCONT=4'
	fi

	#Check if default context APN is empty.
	#If firmware is old enough, where only default pdp was used,
	# it can be not empty, so check and clean
	local cgdcont_resp=`gsmctl -A 'AT+QICSGP=1'`
	if [ "$cgdcont_resp" != "ERROR" ]; then
		gsmctl -A 'AT+QICSGP=1,1,""'
	fi

	#Check if secondary pdp context is defined.
	#It is needed for quectel-CM conn manager to establish connection
	# when APN is used
	cgdcont_resp=`gsmctl -A 'AT+QICSGP=3'`
	if [ "$cgdcont_resp" != "ERROR" ]; then
		gsmctl -A 'AT+QICSGP=3,1,""'
	fi

	#These variables need to be exported to udhcpc's mobile.script.
	#quectel-CM starts udhcpc when data connection is active,
	#proto_init_update and proto_send_update moved to mobile.script

	#Start connection manager and tell to send connection established notification to our pid

	#workaround for eg25g modules
        module_name=`gsmctl -n -y | cut -b 1-5`
        if [ "$module_name" == "EG25G" ]; then
		proto_run_command "$1" /usr/sbin/quectel-CM -n 1 ${apn:+-s $apn ${username:+$username ${password:+$password ${auth_mode:+$auth_mode} } } } ${interface:+-c $interface} $pdptype
        else
		proto_run_command "$1" /usr/sbin/quectel-CM ${apn:+-s $apn ${username:+$username ${password:+$password ${auth_mode:+$auth_mode} } } } ${interface:+-c $interface} $pdptype
	fi

}

proto_qmi2_teardown() {
	local interface="$1"
	echo "teardown: $1"
	#Stop connection manager. If proto_run_command is used, quectel-CM is killed automatically, when ifdown or connection failure happens.
	proto_init_update "*" 0
	proto_send_update "$interface"
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol qmi2
}

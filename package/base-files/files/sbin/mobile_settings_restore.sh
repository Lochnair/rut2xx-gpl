#!/bin/sh

if ! [ -e /etc/config/network ]; then
	echo "Network config not found"
	exit 1
fi

changed="0"

#Get saved  3G and LAN settings
/sbin/keep_settings_new.sh restore network.ppp simcard.sim1 > /tmp/keep_settings.log

if [ $? -eq 0 ]; then
	echo "Restoring saved 3G and LAN settings"
	ifname=`uci -q get network.ppp.ifname`
	if [ $ifname ]; then
		uci -q set network.wan.ifname=$ifname
		if [ "$ifname" == "eth2" ]; then
			uci set network.wan.proto="dhcp"
		elif [ "$ifname" == "3g-ppp" ] || [ "$ifname" == "wwan0" ]; then
			uci set network.wan.proto="none"
		fi
	fi
	/sbin/keep_settings_new.sh delete
	changed="1"
	#Don't do firstboot stuff
	uci -q delete teltonika.sys.first_login=0
	uci commit teltonika

else
	echo "keep_settings_new.sh failed"
fi

#Get saved SIM PIN
pin=`/sbin/mnf_info simpin`
if [ -n "$pin" ]; then
	echo "Restoring saved SIM PIN"
	uci set network.ppp=interface
	uci set network.ppp.pincode="$pin"
	uci set simcard.sim1.pincode="$pin"
	changed="1"
fi
if [ "$changed" == "1" ]; then
	echo "Committing"
	uci commit simcard
	uci commit network
fi

exit 0

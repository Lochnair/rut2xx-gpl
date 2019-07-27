#!/bin/sh

is_ioman=`uci get hwinfo.hwinfo.in_out`
if [ "$is_ioman" == "1" ]; then
	if [ ! -f /tmp/ioman_output_invert.txt ]; then
		echo "File not found!"
		collector=`uci get ioman.ioman.active_DOUT1_status`
		if [ "$collector" == "0" ]; then
			/sbin/gpio.sh clear DOUT1
		fi
		echo "1" > /tmp/ioman_output_invert.txt
	fi
fi

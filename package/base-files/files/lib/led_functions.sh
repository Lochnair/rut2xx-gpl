#!/bin/sh

#
# Helper functions for LED control
#
# (c) 2014 Teltonika

LED_PATH="/sys/class/leds"

led_2g="status_2g"
led_3g="status_3g"
led_4g="status_4g"
led_signal0="signal_bar0"
led_signal1="signal_bar1"
led_signal2="signal_bar2"
led_signal3="signal_bar3"
led_signal4="signal_bar4"

led_init()
{
	trigger_path="$LED_PATH/$1/trigger"
	if ! [ -f "$trigger_path" ]
	then
		echo "$0: file $trigger_path not found"
		logger -t $0 "file $trigger_path not found"
	fi
	
	echo "none" > $trigger_path
}

all_init()
{
	led_init $led_2g
	led_init $led_3g
	led_init $led_4g
	led_init $led_signal0
	led_init $led_signal1
	led_init $led_signal2
	led_init $led_signal3
	led_init $led_signal4

}

gpio_init()
{
	if [ "`ls /sys/class/gpio/ | grep -c -e ^gpio$1$`" == "0" ]
	then
		echo $1 > /sys/class/gpio/export
	fi
	
	if [ "$(cat /sys/class/gpio/gpio$1/direction)" != "out" ]
	then
		echo "out" > /sys/class/gpio/gpio$1/direction
	fi
	
	return $?
}

led_on()
{
	bright_path="$LED_PATH/$1/brightness"
	echo "0" > $bright_path
}

led_off()
{
	bright_path="$LED_PATH/$1/brightness"
	echo "1" > $bright_path
}

all_off()
{
	led_off $led_2g
	led_off $led_3g
	led_off $led_4g
	led_off $led_signal0
	led_off $led_signal1
	led_off $led_signal2
	led_off $led_signal3
	led_off $led_signal4
}
all_signal_off()
{
	led_off $led_signal0
	led_off $led_signal1
	led_off $led_signal2
	led_off $led_signal3
	led_off $led_signal4
}

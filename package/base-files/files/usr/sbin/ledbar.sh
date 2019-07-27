#!/bin/sh

#
# Control bar LEDs
#
# (c) 2014 Teltonika

. /lib/led_functions.sh

show_options()
{
	printf "usage: $0 <number of leds>\n"
}

blink_leds()
{
	echo "timer" > "$LED_PATH/$led_2g/trigger"
	echo "timer" > "$LED_PATH/$led_3g/trigger"
	echo "timer" > "$LED_PATH/$led_4g/trigger"
	echo "timer" > "$LED_PATH/$led_signal0/trigger"
	echo "timer" > "$LED_PATH/$led_signal1/trigger"
	echo "timer" > "$LED_PATH/$led_signal2/trigger"
	echo "timer" > "$LED_PATH/$led_signal3/trigger"
	echo "timer" > "$LED_PATH/$led_signal4/trigger"
	exit 0
}

if [ -n "$1" ] && [ "$1" != "blink" ] && [ "$1" -gt 4 ]
then
	show_options
	exit 1
fi

all_init
all_off


[ -z "$1" ] && exit 0

[ "$1" = "blink" ] && blink_leds $2

[ "$1" -ge 0 ] && led_on $led_signal0
[ "$1" -ge 1 ] && led_on $led_signal1
[ "$1" -ge 2 ] && led_on $led_signal2
[ "$1" -ge 3 ] && led_on $led_signal3
[ "$1" -ge 4 ] && led_on $led_signal4

exit 0


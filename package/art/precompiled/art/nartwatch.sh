#!/bin/bash

while true
do
	if ! pgrep -x "nart.out" > /dev/null
	then
		/art/nart.out&
	fi
	sleep 3;
done

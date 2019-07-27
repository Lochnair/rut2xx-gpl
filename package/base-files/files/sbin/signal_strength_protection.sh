#!/bin/sh

echo -ne "0" > /tmp/events_reporting_block
`sed -i "/signal_strength_protection.sh/d" /etc/crontabs/root`

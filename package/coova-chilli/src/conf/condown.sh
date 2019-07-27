#!/bin/sh

statistics condown

if [[ -n "$SMSOTPMODE" -a "$SMSOTPMODE" == "1" ]]; then
    if [[ -n "$USER_NAME" -a -n "$DHCPIF" ]]; then
      sed -i "/${USER_NAME}/d" /etc/chilli/${DHCPIF}/smsusers
    fi
fi

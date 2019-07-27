#! /bin/sh
mdcollectd=$(uci -q get mdcollectd.config.enabled)
datalimit=$(uci -q get mdcollectd.config.datalimit)
traffic=$(uci -q get mdcollectd.config.traffic)
sim_switch=$(uci -q get mdcollectd.config.sim_switch)
enb_datalimit=0
enb_sim_switch=0
enb_mdcollectd=0

if  [ "$datalimit" = "1" ]; then
    /etc/init.d/limit_guard stop 
     enb_datalimit="1"
fi

if  [ "$sim_switch" = "1" ]; then
    /etc/init.d/sim_switch stop
    enb_sim_switch="1"
fi
#~ Sustabdomas mdcollect
/etc/init.d/mdcollectd stop #&
#sleep 1

#~ Pasalinam standartines duombazes
rm /var/mdcollectd*
rm /usr/lib/mdcollectd/mdcollectd.db_*
rm /tmp/limit_total_data
sleep 1
#~ Paleidziam is naujo
/etc/init.d/mdcollectd restart #&
retval=0 # Pasalintas del netinkamo veikimo $( /usr/bin/mdcollectdctl -clear )

if  [ "$enb_datalimit" = "1" ]; then
     uci -q set network.ppp.enabled=1
     uci -q set network.ppp.overlimit=0
     uci commit
     ifup ppp
     #~ luci-reload 2>/dev/null 1>/dev/null
    /etc/init.d/limit_guard restart 2>/dev/null
fi

if  [ "$enb_sim_switch" = "1" ]; then
    /etc/init.d/sim_switch start
fi

echo "$retval"
exit "$retval"

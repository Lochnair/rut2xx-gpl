-- Copyright 2009-2010 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local uci = require "luci.model.uci".cursor()
local utl = require ("luci.util")
local sys = require("luci.sys")

m = Map("network", translate("Create SSTP Interface"))
m.redirect = luci.dispatcher.build_url("admin/services/vpn/sstp/")

s = m:section(TypedSection, "interface", translate("SSTP Configuration"))
s.addremove = true
s.extedit = luci.dispatcher.build_url("admin", "services", "vpn", "sstp", "%s")
s.template = "sstp/tblsection_sstp"
s:depends("proto", "sstp") -- Only show those with "gre"
s.defaults.proto = "sstp"
s.novaluetext = translate("There are no SSTP Tunnel configurations yet")

local name = s:option( DummyValue, "name", translate("Tunnel name"), translate("Name of the tunnel. Used for easier tunnels management purpose only"))

function name.cfgvalue(self, section)
    return section or "Unknown"
end

o = s:option(Flag, "enabled", "Enabled") -- Creates an element list (select box)
o.rmempty = false

function m.on_commit(map)
    clients = string.gsub(utl.trim(sys.exec("cat /etc/config/network | grep 'sstp_name' | awk '{print $3}'")),"'","")
    clients = clients:split("\n")
    for i = 1, #clients do
        VPN_INST = clients[i]
        local sstpEnable = m:formvalue("cbid.network." .. VPN_INST .. ".enabled")
        if sstpEnable then
            sys.call("ifup " .. VPN_INST .. " > /dev/null")
        else
            sys.call("ifdown " .. VPN_INST .. " > /dev/null")
        end
    end
end

return m

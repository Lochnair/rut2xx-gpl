--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: openvpn.lua 7362 2011-08-12 13:16:27Z jow $
]]--

module("luci.controller.openvpn", package.seeall)
local uci = require "luci.model.uci"
local _uci_real = uci.cursor()

function index()
	entry( {"admin", "services", "vpn"}, alias("admin", "services", "vpn", "openvpn-tlt"), _("VPN"), 54)
	entry( {"admin", "services", "vpn", "openvpn-tlt"}, arcombine(cbi("openvpn"), cbi("cbasic")), _("OpenVPN"), 1).leaf=true
	entry( {"admin", "services", "vpn", "gre-tunnel"}, arcombine(cbi("gre-tunnel/gre-tunnel"), cbi("gre-tunnel/gre-tunnel_edit")), _("GRE Tunnel"), 3).leaf=true
	entry( {"admin", "services", "vpn", "pptp"}, arcombine( cbi("pptp/pptp"),cbi("pptp/pptp_edit")), _("PPTP"), 4).leaf=true
	entry( {"admin", "services", "vpn", "l2tp"}, arcombine( cbi("l2tp/l2tp"),cbi("l2tp/l2tp_edit")), _("L2TP"), 5).leaf=true
	entry( {"admin", "services", "vpn", "sstp"}, arcombine( cbi("sstp/sstp"),cbi("sstp/sstp_edit")), _("SSTP"), 6).leaf=true
	page = entry({"admin", "services", "vpn", "openvpn_delete"}, call("openvpn_delete"), nil)
	page.leaf = true
	page = entry({"admin", "services", "vpn", "gre_delete"}, call("gre_delete"), nil)
	page.leaf = true
	page = entry({"admin", "services", "vpn", "l2tp_delete"}, call("l2tp_delete"), nil)
	page.leaf = true
	page = entry({"admin", "services", "vpn", "pptp_delete"}, call("pptp_delete"), nil)
	page.leaf = true
end

function openvpn_delete()
	local path  = luci.dispatcher.context.requestpath
	local vpn = path[#path]
	if vpn then
		_uci_real:delete_all("openvpn", "client",
			function(s) return (s.sname == vpn) end)
		_uci_real:delete("openvpn", vpn)
		_uci_real:commit("openvpn")
		_uci_real:delete("overview", "show", "open_vpn_" .. vpn)
		_uci_real:commit("overview")
		luci.sys.call("/sbin/luci-reload & >/dev/null 2>/dev/null")
		luci.sys.exec("rm /tmp/openvpn-" .. vpn .. ".status")
		luci.http.redirect(luci.dispatcher.build_url("admin/services/vpn"))
		return
	end
end

function gre_delete()
	local path  = luci.dispatcher.context.requestpath
	local vpn = path[#path]
	if vpn then
		luci.sys.call("ip tunnel del "..vpn.." 2> /dev/null ")
		luci.sys.call("logger [GRE-TUN] "..vpn.." Cleaning up...")
		luci.sys.call("pid=`ps -w | grep gre-tunnel-keep | grep "..vpn.." | awk -F ' ' '{print $1}'`; kill -9 $pid 2>/dev/null")
		_uci_real:delete("gre_tunnel", vpn)
		luci.http.redirect(luci.dispatcher.build_url("admin/services/vpn/gre-tunnel"))
		luci.sys.call("/etc/init.d/gre-tunnel restart >/dev/null")
		_uci_real:commit("gre_tunnel")
		luci.sys.call("/sbin/luci-reload & >/dev/null 2>/dev/null")
		return
	end
end

function l2tp_delete()
	local path  = luci.dispatcher.context.requestpath
	local vpn = path[#path]
	local client, server
	client = _uci_real:get("network", vpn)
	--~ server = _uci_real:get("xl2tpd", "xl2tpd", "_name")
	if vpn then
		if client then
			_uci_real:delete("network", vpn)
			_uci_real:commit("network")
		elseif "xl2tpd" == vpn then
			_uci_real:foreach("firewall", "rule", function(x)
				if x._name == "l2tpd" then
					_uci_real:set("firewall", x[".name"], "enabled", "0")
				end
			end)
			_uci_real:save("firewall")
			_uci_real:commit("firewall")
			_uci_real:delete("xl2tpd", "xl2tpd")
			_uci_real:commit("xl2tpd")
		end
		luci.http.redirect(luci.dispatcher.build_url("admin/services/vpn/l2tp"))
		luci.sys.call("/sbin/luci-reload & >/dev/null 2>/dev/null")
		return
	end
end

function pptp_delete()
	local path  = luci.dispatcher.context.requestpath
	local vpn = path[#path]
	local client, server
	client = _uci_real:get("network", vpn)
	if vpn then
		if client then
			_uci_real:delete("network", vpn)
			_uci_real:commit("network")
		elseif "pptpd" == vpn then
			_uci_real:delete("pptpd", "pptpd")
			_uci_real:commit("pptpd")
		end
		luci.http.redirect(luci.dispatcher.build_url("admin/services/vpn/pptp"))
		luci.sys.call("/sbin/luci-reload & >/dev/null 2>/dev/null")
		return
	end
end

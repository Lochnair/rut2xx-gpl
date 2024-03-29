--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: coovachilli.lua 3442 2008-09-25 10:12:21Z jow $
]]--
local ds = require "luci.dispatcher"
local function debug(string)
	luci.sys.call("logger \"" .. string .. "\"")
end
arg[1] = arg[1] or ""

m = Map( "coovachilli",	translate( "Hotspot Configuration" ), translate( "" ))
	local id = m.uci:get("coovachilli", arg[1], "id") or ""
	m.redirect = ds.build_url("admin/services/hotspot/general/" .. id)
	if m.uci:get("coovachilli", arg[1]) ~= "users" then
		luci.http.redirect(ds.build_url("admin/services/hotspot/general/" .. id))
		return
	end

users = m:section(NamedSection, arg[1], "user", translate( "Users Configuration Settings"))

template = users:option(ListValue, "template", "Session template")
	local hotspot_id = m.uci:get(template.config, arg[1], "id")

	m.uci:foreach(template.config, "session", function(sec)
		if sec.id and sec.id == hotspot_id then
			if sec.name then
				template:value(sec[".name"], sec.name)
			end
		end
	end)

name = users:option(Value, "username", translate("User name"), translate("" ))
	name.rmempty = false
	name.datatype = "uciname"

pass = users:option(Value, "password", translate("User password"), translate("" ))
	pass.password = true
	pass.noautocomplete = true
	pass.rmempty = false
	pass.datatype = "nospace"

return m

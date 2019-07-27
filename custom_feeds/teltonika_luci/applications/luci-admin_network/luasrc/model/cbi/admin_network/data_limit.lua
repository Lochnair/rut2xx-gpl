
local utl = require "luci.util"
local nw = require "luci.model.network"
local sys = require "luci.sys"
local moduleVidPid = utl.trim(sys.exec("uci get -q system.module.vid")) .. ":" .. utl.trim(sys.exec("uci get -q system.module.pid"))
local moduleType = luci.util.trim(luci.sys.exec("uci get -q system.module.type"))
local m
local function cecho(string)
	luci.sys.call("echo \"" .. string .. "\" >> /tmp/luci.log")
end

m = Map("data_limit", translate("Mobile Data Limit Configuration"))
m.disclaimer_msg = true

s = m:section(NamedSection, "limit", "limit");
s.addremove = false

-----------------------
--Primary taboptions---
-----------------------
e = s:option(Value, "field1")
e.template = "cbi/legend"
e.titleText = "Data Connection Limit Configuration"

prim_enb_conn = s:option(Flag, "prim_enb_conn", translate("Enable data connection limit"), translate("Disables mobile data when a limit for current period is reached"))
prim_enb_conn.rmempty = false

o1 = s:option(Value, "prim_conn_limit", translate("Data limit* (MB)"), translate("Disable mobile data after limit value in MB is reached"))
--o1:depends("enb_limit", "1")

function o1:validate(Value)
	local failure
	if Value == nil or Value == "" then
		m.message = translate("err: mobile data limit value is empty!")
		return nil
	elseif not Value:match("^[1-9]%d*$") then
		m.message = translate("err: mobile data limit value is incorrect!")
		return nil
	end
	return Value
end

o = s:option(ListValue, "prim_conn_period", translate("Period"), translate("Period for which mobile data limiting should apply"))
o:value("month", translate("Month"))
o:value("week", translate("Week"))
o:value("day", translate("Day"))

o = s:option(ListValue, "prim_conn_day", translate("Start day"), translate("A starting day in a month for mobile data limiting period"))
o:depends({prim_conn_period = "month"})
for i=1,31 do
	o:value(i, i)
end

o = s:option(ListValue, "prim_conn_hour", translate("Start hour"), translate("A starting hour in a day for mobile data limiting period"))
o:depends({prim_conn_period = "day"})
for i=1,23 do
	o:value(i, i)
end
o:value("0", "24")

o = s:option(ListValue, "prim_conn_weekday", translate("Start day"), translate("A starting day in a week for mobile data limiting period"))
o:value("1", translate("Monday"))
o:value("2", translate("Tuesday"))
o:value("3", translate("Wednesday"))
o:value("4", translate("Thursday"))
o:value("5", translate("Friday"))
o:value("6", translate("Saturday"))
o:value("0", translate("Sunday"))
o:depends({prim_conn_period = "week"})


--------------------------------------------------------------------------------
--------------------SMS warninig------------------------------------------------
--------------------------------------------------------------------------------

e = s:option(Value, "field2")
e.template = "cbi/legend"
e.titleText = "SMS Warning Configuration"

prim_enb_wrn = s:option(Flag, "prim_enb_wrn", translate("Enable SMS warning"), translate("Enables sending of warning SMS message when mobile data limit for current period is reached"))
prim_enb_wrn.rmempty = false

o = s:option(Value, "prim_wrn_limit", translate("Data limit* (MB)"), translate("Send warning SMS message after limit value in MB is reached"))
--o1:depends("enb_limit", "1")

function o:validate(Value)
	local failure
	if Value == nil or Value == "" then
		m.message = translate("err: mobile data limit value is empty!")
		return nil
	elseif not Value:match("^[1-9]%d*$") then
		m.message = translate("err: mobile data limit value is incorrect!")
		return nil
	end
	return Value
end

o = s:option(ListValue, "prim_wrn_period", translate("Period"), translate("Period for which SMS warning for mobile data limit should apply"))
o:value("month", translate("Month"))
o:value("week", translate("Week"))
o:value("day", translate("Day"))

o = s:option(ListValue, "prim_wrn_day", translate("Start day"), translate("A starting day in a month for mobile data limit SMS warning"))
o:depends({prim_wrn_period = "month"})
for i=1,31 do
	o:value(i, i)
end

o = s:option(ListValue, "prim_wrn_hour", translate("Start hour"), translate("A starting hour in a day for mobile data limit SMS warning"))
o:depends({prim_wrn_period = "day"})
for i=1,23 do
	o:value(i, i)
end
o:value("0", "24")

o = s:option(ListValue, "prim_wrn_weekday", translate("Start day"), translate("A starting day in a week for mobile data limit SMS warning"))
o:value("1", translate("Monday"))
o:value("2", translate("Tuesday"))
o:value("3", translate("Wednesday"))
o:value("4", translate("Thursday"))
o:value("5", translate("Friday"))
o:value("6", translate("Saturday"))
o:value("0", translate("Sunday"))
o:depends({prim_wrn_period = "week"})


e = s:option(Value, "prim_wrn_number", translate("Phone number"), translate("A phone number to send warning SMS message to, e.g. +37012345678"))

--------------------------------------------------------------------------------
-------------------- Delete clear data ----------------------------------------
--------------------------------------------------------------------------------

s2 = m:section(NamedSection, "limit", "limit",  translate("Clear Data Limit"));

o = s2:option(Button, "_clear")
o.template  = "admin_network/button"
o.title = translate("Clear data limit")
o.inputtitle = translate("Clear")
o.inputstyle = "apply"
o.onclick = true

function m.on_parse(self)
	if m:formvalue("cbid.data_limit.limit._clear") then
		luci.sys.exec("/sbin/clear_data_limit.sh")
		luci.sys.exec("logger mdcollectd database cleared!")
	end
end

function m.on_commit(map)
	local primEnbCon = prim_enb_conn:formvalue("limit")
	local primEnbWrn = prim_enb_wrn:formvalue("limit")
	if primEnbCon == "1" or primEnbWrn == "1" then
		m.uci:set("mdcollectd", "config", "datalimit", "1")
		m.uci:set("mdcollectd", "config", "interval", "10")
		m.uci:set("overview", "show", "data_limit", "1")
		m.uci:commit("overview")
	else
		m.uci:set("mdcollectd", "config", "datalimit", "0")
		m.uci:set("overview", "show", "data_limit", "0")
		m.uci:commit("overview")
	end
	m.uci:save("mdcollectd")
	m.uci:commit("mdcollectd")
	luci.sys.exec("/etc/init.d/limit_guard restart >/dev/null 2>/dev/null")
end

return m


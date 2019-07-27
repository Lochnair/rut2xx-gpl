local sys = require "luci.sys"
local dsp = require "luci.dispatcher"
local ft = require "luci.tools.input-output"
local utl = require "luci.util"

local m, s, o

arg[1] = arg[1] or ""

m = Map("ioman", translate("Custom I/O Status Labels"))
m.redirect = dsp.build_url("admin/services/input-output/")

if arg[1] == "1" then	
	s = m:section(NamedSection, "iolabels", "iostatus", translate("Customize Digital input and state fields"))
	o = s:option(Value, "digitalinput", translate("Digital Input name"), translate("Digital input label"))
	o = s:option(Value, "dishorted", translate("Input shorted state"), translate("Digital input label"))
	o = s:option(Value, "diopen", translate("Input open state"), translate("Digital input label"))
end

if arg[1] == "2" then
	s = m:section(NamedSection, "iolabels", "iostatus", translate("Customize Digital galvanicaly isolated input and state fields"))
	o = s:option(Value, "digitaloutput", translate("Digital output name"), translate("Digital output label"))
	o = s:option(Value, "diouthigh", translate("High logic level state"), translate("Digital output label"))
	o = s:option(Value, "dioutlow", translate("Low logic level state"), translate("Digital output label"))
end

if arg[1] == "3" then
	s = m:section(NamedSection, "iolabels", "iostatus", translate("Customize Analog input and value fields"))
	s.template_addremove = "input-output/analogfield"

	o = s:option(Value, "anformultiply")
	o.datatype = "range(-999999,999999)"
	o = s:option(Value, "anforoffset")
	o.datatype = "range(-999999,999999)"
	o = s:option(Value, "anforadd")
	o.datatype = "range(-999999,999999)"
	o = s:option(Value, "anfordivide")
	o.datatype = "range(0.000001,999999)"
	o = s:option(Value, "analoginput", translate("Analog Input name"))
	o = s:option(Value, "anformeasunit", translate("User defined unit of measurement"))
end

if arg[1] == "4" then
	s = m:section(NamedSection, "iolabels", "iostatus", translate("Customize Open collector output and state fields"))
	o = s:option(Value, "opencollector", translate("Open Collector Output name"), translate("Digital input label"))
	o = s:option(Value, "ocouton", translate("Open collector active state"), translate("Digital input label"))
	o = s:option(Value, "ocoutoff", translate("Open collector inactive state"), translate("Digital input label"))
end

if arg[1] == "5" then
	s = m:section(NamedSection, "iolabels", "iostatus", translate("Customize Relay output and state fields"))
	o = s:option(Value, "relayoutput", translate("Relay Output name"), translate("Digital input label"))
	o = s:option(Value, "relon", translate("Relay out active state"), translate("Digital input label"))
	o = s:option(Value, "reloff", translate("Relay out inactive state"), translate("Digital input label"))
end

if arg[1] == "del" then
	m = Map("ioman", translate("Press \"Save\" button to restore default I/O status labels"))
	m.redirect = dsp.build_url("admin/services/input-output/")	
	--	luci.sys.exec("uci commit ioman")
	function m.on_commit()
		luci.sys.exec("uci delete ioman.iolabels")
		luci.sys.exec("uci set ioman.iolabels=iostatus")
		m.uci.commit("ioman")
	end
else
	s.addremove = false
	s.anonymous = true
	s.rmempty = false
end

return m
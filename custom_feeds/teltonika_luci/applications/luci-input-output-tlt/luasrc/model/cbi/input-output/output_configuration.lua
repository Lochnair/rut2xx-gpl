local sys = require "luci.sys"
local dsp = require "luci.dispatcher"
local ft = require "luci.tools.input-output"
local utl = require "luci.util"

local m, s, o

arg[1] = arg[1] or ""

m = Map("ioman",
	translate("Output Configuration"))
	
function get_status(out)
	return utl.trim(luci.sys.exec("/sbin/gpio.sh get " .. out))
end

function get_config(out)
	return utl.trim(luci.sys.exec("uci get ioman.ioman.active_"..out.."_status"))
end
s = m:section(TypedSection, "ioman", translate("Output configuration in active state"))
state = s:option(ListValue, "active_DOUT1_status", translate("Open collector output"), translate(""))
state:value("0", translate("Low level"))
state:value("1", translate("High level"))
function state.write(self, section, value)
	local open_collector_output = get_status("DOUT1")
	local open_collector_output_cfg = get_config("DOUT1")
	if value ~= open_collector_output_cfg then
		if open_collector_output_cfg == "1" then
			if open_collector_output == "1" then
				luci.sys.exec("/sbin/gpio.sh clear DOUT1")
			else
				luci.sys.exec("/sbin/gpio.sh set DOUT1")
			end
		else
			if open_collector_output == "1" then
				luci.sys.exec("/sbin/gpio.sh set DOUT1")
			else
				luci.sys.exec("/sbin/gpio.sh clear DOUT1")
			end
		end
	end
	luci.sys.call("uci set ioman.ioman.active_DOUT1_status=" .. value)
end

return m

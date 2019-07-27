local fw = require "luci.model.firewall"
local deathTrap = { }
m = Map("modbus", translate("Modbus TCP"))
m:chain("firewall")
fw.init(m.uci)
s = m:section(NamedSection, "modbus", "modbus", translate(""), "")
enabled = s:option(Flag, "enabled", "Enable", translate("Enable Modbus TCP"))
port = s:option(Value, "port", "Port", translate("Port number"))
port.datatype = "port"
allow_ra = s:option(Flag, "allow_ra", "Allow Remote Access", translate("Allow access through WAN"))
allow_ra.default = "0"
allow_ra.rmempty = false
function allow_ra.write(self, section)
	local fval = self:formvalue(section)
	local fport = port:formvalue(section)
	local needsPortUpdate = false
	local fwRuleInstName = "nil"
	
	if not deathTrap[1] then 
		deathTrap[1] = true
	else 
		return 
	end
	
	if not fval then
		fval = "0"
	else
		fval = "1"
	end
	
	m.uci:foreach("firewall", "rule", function(z)
		if z.name == "Enable_MODBUSD_WAN" then
			fwRuleInstName = z[".name"]
			if z.dest_port ~= fport then
				needsPortUpdate = true
			end
			if z.enabled ~= fval then
				needsPortUpdate = true
			end
		end
	end)
	
	if needsPortUpdate == true then
		m.uci:set("firewall", fwRuleInstName, "dest_port", fport)
		m.uci:set("firewall", fwRuleInstName, "enabled", fval)
		m.uci:save("firewall")
	end
	
	if fwRuleInstName == "nil" then
		local wanZone = fw:get_zone("wan")
		if not wanZone then
			m.message = "Could not add firewall rule"
			return
		end
		local fw_rule = {
			name = "Enable_MODBUSD_WAN",
			target = "ACCEPT",
			proto = "tcp",
			dest_port = fport,
			enabled = fval
		}
		wanZone:add_rule(fw_rule)
		m.uci:save("firewall")
	end
end				

function allow_ra.cfgvalue(self, section)
	local fwRuleEn = false
	
	m.uci:foreach("firewall", "rule", function(z)
		if z.name == "Enable_MODBUSD_WAN" and z.enabled == "1" then
			fwRuleEn = true
		end
	end)
	if fwRuleEn then
		return self.enabled
	else
		return self.disabled
	end
end


m2 = Map("mdcollectd", translate(""), translate(""))
m2.addremove = false

s = m2:section(NamedSection, "config", "mdcollectd");
s.addremove = false

o = s:option(Flag, "traffic", translate("Mobile Traffic Usage Logging"), translate('Check to enable mobile traffic usage logging (necessary for mobile data counters to be available at modbus registers)'))
o.rmempty = false

		
return m, m2



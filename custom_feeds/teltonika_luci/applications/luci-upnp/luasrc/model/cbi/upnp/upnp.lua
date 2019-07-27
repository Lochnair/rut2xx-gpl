-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2008-2011 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local sys = require "luci.sys"
local uci = require "uci".cursor()
local bus = require "ubus"

m = Map("upnpd", translate("Universal Plug & Play"),
	translate("UPnP allows clients in the local network to automatically configure the router."))

m:section(SimpleSection).template  = "upnp_status"

s = m:section(NamedSection, "config", "upnpd", translate("MiniUPnP settings"))
s.addremove = false
s:tab("general",  translate("General Settings"))
s:tab("advanced", translate("Advanced Settings"))

e = s:taboption("general", Flag, "enabled", translate("Enabled"))
e.rmempty  = false

	function e.parse(self, section)
		local ubus = bus.connect()
		local enabled = self:formvalue(section) and self.enabled or self.disabled
		if enabled and enabled == "1" then
			local main_interface = luci.sys.exec("/sbin/route | grep default | head -n1 | awk -F ' ' '{ printf $8}'")
			if main_interface and #main_interface == 0 then
				m.message = "err: External interface is not set up. UPnPd will not start"
				self:write(section, self.disabled)
				return
			end
			local exists = false
			for _, value in ipairs({"ppp", "ppp_4", "wan", "wan2"}) do
				local information = ubus:call("network.interface." .. value, "status", { })
				if information then
					for key, value in pairs(information) do
						if information["device"] == main_interface then
							if key == "ipv4-address" or key == "ipv6-address" then
								if value[1] then
									exists = true
								end
							end
						end
					end
				end
			end
			if not exists then
				m.message = "err: External interface is not set up. UPnPd will not start."
				self:write(section, self.disabled)
				return
			end
		end
		Flag.parse(self, section)
	end

s:taboption("general", Flag, "secure_mode", translate("Enable secure mode"),
	translate("Allow adding forwards only to requesting ip addresses")).default = "1"

s:taboption("general", Flag, "log_output", translate("Enable additional logging"),
	translate("Puts extra debugging information into the system log"))

s:taboption("general", Value, "download", translate("Downlink"),
	translate("Value in KByte/s, informational only")).rmempty = true

s:taboption("general", Value, "upload", translate("Uplink"),
	translate("Value in KByte/s, informational only")).rmempty = true

port = s:taboption("general", Value, "port", translate("Port"))
port.datatype = "port"
port.default  = 5000

s:taboption("advanced", Flag, "system_uptime", translate("Report system instead of daemon uptime")).default = "1"

s:taboption("advanced", Value, "uuid", translate("Device UUID"))
s:taboption("advanced", Value, "serial_number", translate("Announced serial number"))
s:taboption("advanced", Value, "model_number", translate("Announced model number"))

ni = s:taboption("advanced", Value, "notify_interval", translate("Notify interval"))
ni.datatype    = "uinteger"
ni.placeholder = 30

ct = s:taboption("advanced", Value, "clean_ruleset_threshold", translate("Clean rules threshold"))
ct.datatype    = "uinteger"
ct.placeholder = 20

ci = s:taboption("advanced", Value, "clean_ruleset_interval", translate("Clean rules interval"))
ci.datatype    = "uinteger"
ci.placeholder = 600

pu = s:taboption("advanced", Value, "presentation_url", translate("Presentation URL"))
pu.placeholder = "http://192.168.1.1/"

lf = s:taboption("advanced", Value, "upnp_lease_file", translate("UPnP lease file"))
lf.placeholder = "/var/log/upnp.leases"


s2 = m:section(TypedSection, "perm_rule", translate("MiniUPnP ACLs"),
	translate("ACLs specify which external ports may be redirected to which internal addresses and ports"))

s2.template  = "cbi/tblsection"
s2.sortable  = true
s2.anonymous = true
s2.addremove = true

s2:option(Value, "comment", translate("Comment"))

ep = s2:option(Value, "ext_ports", translate("External ports"))
ep.datatype    = "portrange"
ep.placeholder = "0-65535"

ia = s2:option(Value, "int_addr", translate("Internal addresses"))
ia.datatype    = "ip4addr"
ia.placeholder = "0.0.0.0/0"

ip = s2:option(Value, "int_ports", translate("Internal ports"))
ip.datatype    = "portrange"
ip.placeholder = "0-65535"

ac = s2:option(ListValue, "action", translate("Action"))
ac:value("allow")
ac:value("deny")

return m

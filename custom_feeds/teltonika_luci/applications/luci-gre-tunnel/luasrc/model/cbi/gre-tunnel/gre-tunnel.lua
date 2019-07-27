-- Copyright 2009-2010 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

local uci = require "luci.model.uci".cursor()

m = Map("network", translate("Create GRE Interface"))
m.redirect = luci.dispatcher.build_url("admin/services/vpn/gre-tunnel/")

s = m:section(TypedSection, "interface", translate("GRE Configuration"))
s.addremove = true
s.extedit = luci.dispatcher.build_url("admin", "services", "vpn", "gre-tunnel", "%s")
s.template = "gre-tunnel/tblsection_gre"
s:depends("proto", "gre") -- Only show those with "gre"
s.defaults.proto = "gre"

function s.parse(self, novld)
	local origin, name = next(self.map:formvaluetable("cbi.cts." .. self.config .. "." .. self.sectiontype))
	if name then
		if self:cfgvalue(name) or name:find("wwan") or name:find("eth") or name:find("wlan")
			or name:find("wan") or name:find("lan") then
			m.message = "err: Name \'" .. name .. "\' cannot be used."
			return
		elseif #name > 10 then
			m.message = "err: Name \'" .. name .. "\' is too long. Maximum 10 characters."
			return
		end
	end
	TypedSection.parse(self, novld)
end

function s.create(self, section)
	local stat

	if section then
		zzzz = section:match("^[%w_]+$") and self.map:set(section.."_static", nil, self.sectiontype)
		stat = section:match("^[%w_]+$") and self.map:set(section, nil, self.sectiontype)
	else
		section = self.map:add(self.sectiontype)
		stat = section
	end

	if stat then
		for k,v in pairs(self.children) do
			if v.default then
				self.map:set(section, v.option, v.default)
			end
		end

		for k,v in pairs(self.defaults) do
			self.map:set(section, k, v)
		end
	end
	self.map.proceed = true
	return stat
end

function s.remove(self, section)
	self.map.proceed = true

	uci:foreach("network", "route",
	function (s)
		if s.dep == section then
				self.map:del(s[".name"])
		end
	end)

	uci:foreach("network", "interface",
	function (s)
		if s[".name"] == section.."_static" then
				self.map:del(s[".name"])
		end
	end)

	return self.map:del(section)
end

o = s:option(Flag, "disabled", "Enabled") -- Creates an element list (select box)
	o.enabled="0"
	o.disabled="1"
	o.default = "0"

return m

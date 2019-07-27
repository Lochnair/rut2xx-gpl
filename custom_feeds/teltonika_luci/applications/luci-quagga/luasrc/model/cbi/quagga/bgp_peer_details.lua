local dsp = require "luci.dispatcher"

m=Map("quagga", "BGP peer configuration")
  m.redirect = dsp.build_url("admin/network/routes/dynamic_routes/proto_bgp")

sect_peer = m:section(NamedSection, arg[1], "peer", "BGP peer", "")
	sect_peer.anonymous = false

sect_peer:option(Flag, "enabled", "Enable", "Enable/Disable BGP peer")

o = sect_peer:option(Value, "as", "Remote AS", "")
	o.datatype = "integer"
o = sect_peer:option(Value, "ipaddr", "Remote address", "")
	o.datatype = "ip4addr"
o = sect_peer:option(Value, "port", "Remote port", "")
	o.datatype = "port"
sect_peer:option(Flag, "default_originate", "Default originate", "Announce default routes to the peer")
sect_peer:option(Value, "description", "Description")

return m

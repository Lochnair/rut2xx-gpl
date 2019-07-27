--[[
Copyright (C) 2014 - Eloi Carbó Solé (GSoC2014)
BGP/Bird integration with OpenWRT and QMP

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
--]]

module("luci.controller.quagga", package.seeall)

function index()
	entry({"admin", "network", "routes", "dynamic_routes"}, alias("admin", "network", "routes", "dynamic_routes", "proto_bgp"), _("Dynamic Routes"), 2)
	entry({"admin","network","routes","dynamic_routes","proto_bgp"}, cbi("quagga/bgp_proto"), _("BGP Protocol"), 37).dependent=false
		entry({"admin","network","routes","dynamic_routes","bgp_peer"}, cbi("quagga/bgp_peer_details"), nil).leaf=true
		entry({"admin","network","routes","dynamic_routes","bgp_instance"}, cbi("quagga/bgp_instance_details"), nil).leaf=true
	entry({"admin","network","routes","dynamic_routes","proto_rip"}, cbi("quagga/rip_proto"), _("RIP Protocol"), 38).dependent=false
	entry({"admin","network","routes","dynamic_routes","proto_ospf"}, cbi("quagga/ospf_proto"), _("OSPF Protocol"), 39).dependent=false
		entry({"admin","network","routes","dynamic_routes","basic_interface"}, cbi("quagga/ospf_interface"), nil).leaf = true
-- entry({"admin","network","routes","dynamic_routes", "gen_proto"}, cbi("quagga/gen_proto"), _("General Protocols"), 40).leaf = true
end

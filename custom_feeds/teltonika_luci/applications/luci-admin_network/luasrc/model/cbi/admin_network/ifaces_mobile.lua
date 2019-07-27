--[[
config custom_interface '3g'
        option pin 'kazkas'
        option apn 'kazkas'
        option user 'kazkas'
        option password 'kazkas'
        option auth_mode 'chap' ARBA 'pap' (jei nerandu nieko ar kazka kita, laikau kad auth nenaudojama)
        option net_mode 'gsm' ARBA 'umts' ARBA 'auto' (prefered tinklas. jei nerandu nieko arba kazka kita laikau kad auto)
        option data_mode 'enabled' ARBA 'disabled' (ar leisti siusti duomenis. jei nera nieko ar kazkas kitas, laikau kad enabled)
]]

require "teltonika_lua_functions"
local uci = require "luci.model.uci".cursor()
local utl = require "luci.util"
local nw = require "luci.model.network"
local sys = require "luci.sys"
local ds = require "luci.dispatcher"
local moduleVidPid = utl.trim(sys.exec("uci get -q system.module.vid")) .. ":" .. utl.trim(sys.exec("uci get -q system.module.pid"))
local moduleType = utl.trim(luci.sys.exec("uci get -q system.module.type"))
local m
local modulsevice = "3G"
local modulsevice2 = "0"
local dual_sim = utl.trim(luci.sys.exec("uci get -q hwinfo.hwinfo.dual_sim"))
local call = uci:get("call_utils", "@rule[0]", "action") or "0"
local multiwan_on = utl.trim(luci.sys.exec("uci get -q multiwan.config.enabled")) or "0"

Save_value = 0
local function cecho(string)
	luci.sys.call("echo \"" .. string .. "\" >> /tmp/log.log")
end

local function debug(string, ...)
	luci.sys.call(string.format("/usr/bin/logger -t Webui \"%s\"", string.format(string, ...)))
end

if moduleVidPid == "12D1:1573" or moduleVidPid == "12D1:15C1" or moduleVidPid == "12D1:15C3" then
	modulsevice = "LTE"
elseif moduleVidPid == "1BC7:1201" then
	modulsevice = "TelitLTE"
	modulsevice2 = "2"
elseif moduleVidPid == "1BC7:0036" then
	modulsevice = "TelitLTE_V2"
	modulsevice2 = "2"
elseif moduleVidPid == "1199:68C0" then
	modulsevice = "SieraLTE"
elseif moduleVidPid == "05C6:9215" then
	modulsevice = "QuectelLTE"
	modulsevice2 = "2"
elseif moduleVidPid == "2C7C:0125" then
	modulsevice = "QuectelLTE_EC25"
	modulsevice2 = "2"
elseif moduleVidPid == "05C6:9003" then
	modulsevice = "Quectel_UC20"
	modulsevice2 = "2"
end

--ismtys del telit modemu kurie nepalaiko 2g prefered ir 3g prefered pasirinkimo
if moduleVidPid == "1BC7:0021" then --Telit He910d
	modulsevice2 = "1"
end



-- if moduleType == "3g_ppp" then
	m = Map("simcard", translate("Mobile Configuration"), translate(""))
	m.addremove = false
	nw.init(m.uci)

	s = m:section(NamedSection, "sim1", "", translate("Mobile Configuration"));
	s.addremove = false

	if modulsevice == "LTE" or modulsevice == "TelitLTE" or modulsevice == "TelitLTE_V2" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" or modulsevice == "QuectelLTE_EC25" or modulsevice == "Quectel_UC20" then

		prot = s:option(ListValue, "proto", translate("Connection type"), translate("An underlying agent for mobile data connection creation and management"))
		prot.template = "cbi/lvalue_onclick"
		if modulsevice == "TelitLTE_V2" then
			prot.javascript="mode_list_check('simcard', 'sim1', 'proto', 'method, " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method'); service_mode_list_check('simcard', 'sim1', 'proto', 'service');"
		elseif modulsevice == "Quectel_UC20" then
			--~ modulsevice = "Quectel_UC20"
		else
			prot.javascript="mode_list_check('simcard', 'sim1', 'proto', 'method', " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method');"
		end
		if modulsevice ~= "SieraLTE" then
			prot:value("3g", translate("PPP"))
		end

		if modulsevice == "LTE" then
			prot:value("ndis", translate("NDIS"))
		elseif modulsevice == "TelitLTE" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" then
			prot:value("qmi", translate("QMI"))
		elseif modulsevice == "TelitLTE_V2" then
			prot:value("ncm", translate("NCM"))
		elseif modulsevice == "QuectelLTE_EC25" or modulsevice == "Quectel_UC20" then
			prot:value("qmi2", translate("QMI"))
		end

		function prot.write(self, section, value)
			if value then
				m.uci:set(self.config, section, self.option, value)
				if value == "3g" then
					m.uci:set(self.config, section, "ifname", "3g-ppp")
					m.uci:set(self.config, section, "device", "/dev/modem_data")
				elseif value == "qmi" or value == "qmi2" then
					m.uci:set(self.config, section, "ifname", "wwan0")
					m.uci:set(self.config, section, "device", "/dev/cdc-wdm0")
				elseif value == "ncm" then
					m.uci:set(self.config, section, "ifname", "wwan0")
					m.uci:set(self.config, section, "device", "/dev/modem_data")
				else
					m.uci:set(self.config, section, "ifname", "eth2")
					m.uci:set(self.config, section, "device", "/dev/modem_data")
				end
				m.uci:save("simcard")
				m.uci:commit("simcard")
			end
		end

	end

	method = s:option(ListValue, "method", translate("Mode"), translate("An underlying agent for mobile data connection creation and management"))
		method.template = "cbi/lvalue_onclick"
		if modulsevice == "TelitLTE_V2" then
			method.javascript="mode_list_check('simcard', 'sim1', 'proto', 'method', " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method'); service_mode_list_check('simcard', 'sim1', 'proto', 'service');"
			method.javascript_after_select="mode_list_check('simcard', 'sim1', 'proto', 'method', " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method'); service_mode_list_check('simcard', 'sim1', 'proto', 'service');"
		elseif modulsevice == "Quectel_UC20" then
			--~ modulsevice = "Quectel_UC20" 
		else
			method.javascript="mode_list_check('simcard', 'sim1', 'proto', 'method', " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method')"
			method.javascript_after_select="mode_list_check('simcard', 'sim1', 'proto', 'method', " .. multiwan_on .. "); check_for_message('cbid.simcard.sim1.method')"
		end
		method:value("nat", translate("NAT"))

		if modulsevice == "LTE" or modulsevice == "TelitLTE" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" or modulsevice == "TelitLTE_V2" or modulsevice == "QuectelLTE_EC25" then
			if multiwan_on == "0" then
				method:value("bridge", translate("Bridge"))
			end
		end

		if multiwan_on == "0" then
			method:value("pbridge", translate("Passthrough"))
		end

		method.default = "nat"

		if multiwan_on == "1" then
			method.hardDisabled = true
			method.info = "Passthrough and Bridge modes are disabled when multiwan is enabled"
			method.url = ds.build_url('/admin/network/wan')
		end

		function method.write(self, section, value)
			local v = m.uci.get("simcard", "sim1", "method")
			if v == "pbridge" and value == "nat" then
                                m.uci:delete("dhcp", "lan", "ignore")
                                m.uci:set("dhcp", "dhcp_relay", "enabled", "0")
                                m.uci:commit("dhcp")
                        
			end
			m.uci:set("simcard", "sim1", "method", value)	
			m.uci:commit("simcard")					
		end

	o = s:option(Value, "bind_mac", translate("Bind to MAC"), translate("Forward all incoming packets to specified MAC address e.g. 00:00:00:00:00:00"))
		o:depends({method = "bridge", proto = "qmi"})
		o:depends({method = "bridge", proto = "qmi2"})	
		o.datatype = "macaddr2"

	o = s:option(Value, "apn", translate("APN"), translate("APN (Access Point Name) is a configurable network identifier used by a mobile device when connecting to a GSM carrier"))
	o = s:option(Value, "pincode", translate("PIN number"), translate("SIM card\\'s PIN (Personal Identification Number) is a secret numeric password shared between a user and a system that can be used to authenticate the user"))
		o.datatype = "lengthvalidation(4,12,'^[0-9]+$')"
	o = s:option(Value, "dialnumber", translate("Dialing number"), translate("Dialing number is used to establish a mobile PPP (Point-to-Point Protocol) connection. For example *99#"))
	
	o = s:option(Value, "mtu", translate("MTU"), translate("The size (in bytes or octets) of the largest protocol data unit that the layer can pass onwards"))
		o:depends("proto", "3g")
		o:depends("proto", "qmi2")
		o.default = "1500"
		o.datatype = "range(0,1500)"
	
	auth = s:option(ListValue, "auth_mode", translate("Authentication method"), translate("Authentication method that your GSM carrier uses to authenticate new connections on it\\'s network"))
		auth:value("chap", translate("CHAP"))
		auth:value("pap", translate("PAP"))
		auth:value("none", translate("None"))
		auth.default = "none"

	o = s:option(Value, "username", translate("Username"), translate("Your username that you would use to connect to your GSM carrier\\'s network"))
		o:depends("auth_mode", "chap")
		o:depends("auth_mode", "pap")

	o = s:option(Value, "password", translate("Password"), translate("Your password that you would use to connect to your GSM carrier\\'s network"))
		o:depends("auth_mode", "chap")
		o:depends("auth_mode", "pap")
		o.password = true;
	o = s:option(ListValue, "service", translate("Service mode"), translate("Your network\\'s preference. If your local mobile network supports GSM (2G), UMTS (3G) or LTE (4G) you can specify to which network you prefer to connect to"))
	o.template = "cbi/lvalue_onclick"
	if modulsevice == "TelitLTE_V2" then
		o.javascript="service_mode_list_check('simcard', 'sim1', 'proto', 'service', " .. multiwan_on .. ");"
		o.javascript_after_select="service_mode_list_check('simcard', 'sim1', 'proto', 'service', " .. multiwan_on .. ");"
	end
	--Huawei LTE ME909u

	o:value("gprs-only", translate("2G only"))
	if modulsevice2 == "0" then
		o:value("gprs", translate("2G preferred"))
	end

	o:value("umts-only", translate("3G only"))
	if modulsevice2 == "0" then
		o:value("umts", translate("3G preferred"))
	end

	if moduleVidPid == "12D1:1573" or moduleVidPid == "1BC7:1201" or  moduleVidPid == "12D1:15C1" or  moduleVidPid == "12D1:15C3" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" or modulsevice == "TelitLTE_V2" or modulsevice == "QuectelLTE_EC25" then
		o:value("lte-only", translate("4G (LTE) only"))
		if modulsevice2 == "0" then
			o:value("lte", translate("4G (LTE) preferred"))
		end
		if moduleVidPid == "12D1:1573" then
			o:value("lte-umts", translate("4G (LTE) and 3G only"))
		end
		o:value("auto", translate("Automatic"))
		o.default = "lte"
	else
		o:value("auto", translate("Automatic"))

		if modulsevice2 == "0" then
			o.default = "umts"
		else
			o.default = "auto"
		end
	end
	if call ~= "0" then
		dummy = s:option(DummyValue, "_dummy", " ")
		dummy.template = "cbi/custom_label"
		dummy.customValue = translate("Call utilities will not work as 4G-only service mode is on")
		dummy:depends("service", "lte-only")
	end

	o = s:option(Flag, "roaming", translate("Deny data roaming"), translate("Deny data connection on roaming"))
	o = s:option(Flag, "pdptype", translate("Use IPv4 only"), translate("Specifies the type of packet data protocol"))
	o.rmempty = false

	prot = s:option(ListValue, "passthrough_mode", translate("DHCP mode"), translate(""))
		prot.template = "cbi/lvalue_onclick"
		prot.javascript="check_mod(this.id,'cbid.simcard.sim1.mac')"
		prot:value("static", translate("Static"))
		prot:value("dynamic", translate("Dynamic"))
		prot:value("no_dhcp", translate("No DHCP"))
		prot.default = "static"
		prot:depends("method", "pbridge")

	mac_address = s:option(Value, "mac", translate("MAC Address"), translate(""))
		mac_address:depends("passthrough_mode", "static")
		mac_address.datatype = "macaddr2"
		

	local ltime = s:option(Value, "leasetime", translate("Lease time"), translate("Expire time for leased addresses. Minimum value is 2 minutes"))
		ltime.rmempty = true
		ltime.displayInline = true
		ltime.datatype = "integer"
		ltime.default = "12"
		--ltime:depends("method", "pbridge")
		ltime:depends("passthrough_mode", "static")
		ltime:depends("passthrough_mode", "dynamic")
		
		function ltime.cfgvalue(self, section)
		sim1_leasetime=utl.trim(sys.exec("uci get -q simcard.sim1.leasetime"))
			local value = sim1_leasetime
			local val = value:match("%d+")
			return val
		end
		--~ function ltime.write(self, section, value)
		--~ end

	o = s:option(ListValue, "letter", translate(""), translate(""))
		o:value("h", translate("Hours"))
		o:value("m", translate("Minutes"))
		o.displayInline = true
		--o:depends("method", "pbridge")
		o:depends("passthrough_mode", "static")
		o:depends("passthrough_mode", "dynamic")
		function o.cfgvalue(self, section)
			local value = sim1_leasetime
			if value:find("m") then
				return "m"
			else
				return "h"
			end
		end
		--~ function o.write(self, section, value)
		--~ end

	s1 = m:section(NamedSection, "ppp", "interface", translate("Mobile Data On Demand"));
	s1.addremove = false
	o = s1:option(Flag, "demand_enable", translate("Enable"), translate("Mobile data on demand function enables you to keep mobile data connection on only when it\\'s in use"))
	o.nowrite = true
	o.alert={"1", "Available in ppp mode only"}
	function o.write(self, section, value)
			end
	function o.cfgvalue(self, section)
		local value = m.uci:get("network", section, "demand")
		if value then
			return "1"
		else
			return "0"
		end
	end
	time = s1:option(Value, "demand", translate("No data timeout (sec)"), translate("A mobile data connection will be terminated if no data is transfered during the timeout period"))
	--o:depends("demand_enable", "1")
	time.datatype = "range(10,3600)"
	time.default = "10"

	if moduleVidPid == "12D1:1573" or moduleVidPid == "1BC7:1201" or moduleVidPid == "12D1:15C1" or moduleVidPid == "12D1:15C3" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" or modulsevice == "TelitLTE_V2" or modulsevice == "QuectelLTE_EC25" then
		m2 = Map("reregister")
		m2.addremove = false
		s1 = m2:section(TypedSection, "reregister", translate("Force LTE network"))
		s1.addremove = false
		o3 = s1:option(Flag, "enabled", translate("Enable"), translate("Try to connect to LTE network every x seconds (used only if service mode is set to 4G (LTE) preferred)"))
		o3.rmempty = false
		o = s1:option(Flag, "force_reregister", translate("Reregister"), translate("If this enabled, modem will be reregister before try to connect to LTE network."))
		o.rmempty = false
		interval = s1:option(Value, "interval", translate("Interval (sec)"), translate("Time in seconds between tries to connect to LTE network. Range [180 - 3600]"))
		interval.datatype = "range(180,3600)"
	end

	if moduleVidPid == "2C7C:0125" or modulsevice == "QuectelLTE_EC25" then
		local modem_firmware = utl.trim(sys.exec("gsmctl -A 'AT+CGMR'"))
		local modem_region = nil
		local modem3 = modem_firmware:sub(5, 7)
		local modem2 = modem_firmware:sub(5, 6)
		local modem1 = modem_firmware:sub(5, 5)

		if not modem_region and modem3 and modem3 == "AUT" then
			modem_region = modem3
		end
		if not modem_region and modem2 then
			if modem2 == "EU" or modem2 == "EC" or modem2 == "AU" then
				modem_region = modem2
			end
		end
		if not modem_region and modem1 then
			if modem1 == "E" or modem1 == "J" or modem1 == "A" or modem1 == "V" then
				modem_region = modem1
			end
		end

		if modem_region then
			s2 = m:section(NamedSection, "bands", "bands", translate("Network Frequency Bands"))
			s2.addremove = false
			auto = s2:option(ListValue, "auto_sim", translate("Connection method"), translate("Specify to which network frequency bands connect to"))
			auto:value("enable", translate("Automatic"))
			auto:value("disable", translate("Manual"))
			auto.default = "enable"
		end

		if modem_region == "E" then
			o = s2:option(Flag, "gsm900_sim", translate("GSM900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm1800_sim", translate("GSM1800"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma850_sim", translate("WCDMA 850"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma900_sim", translate("WCDMA 900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb5_sim", translate("LTE B5"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb7_sim", translate("LTE B7"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb8_sim", translate("LTE B8"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb20_sim", translate("LTE B20"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb38_sim", translate("LTE B38"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb40_sim", translate("LTE B40"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb41_sim", translate("LTE B41"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "EU" then
			o = s2:option(Flag, "gsm900_sim", translate("GSM900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm1800_sim", translate("GSM1800"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma900_sim", translate("WCDMA 900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb7_sim", translate("LTE B7"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb8_sim", translate("LTE B8"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb20_sim", translate("LTE B20"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb28_sim", translate("LTE B28A"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb38_sim", translate("LTE B38"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb40_sim", translate("LTE B40"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb41_sim", translate("LTE B41"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "EC" then
			o = s2:option(Flag, "gsm900_sim", translate("GSM900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm1800_sim", translate("GSM1800"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma900_sim", translate("WCDMA 900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb7_sim", translate("LTE B7"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb8_sim", translate("LTE B8"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb20_sim", translate("LTE B20"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb28_sim", translate("LTE B28A"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "A" then
			o = s2:option(Flag, "wcdma850_sim", translate("WCDMA 850"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma1700_sim", translate("WCDMA 1700"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma1900_sim", translate("WCDMA 1900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb2_sim", translate("LTE B2"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb4_sim", translate("LTE B4"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb12_sim", translate("LTE B12"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "V" then
			o = s2:option(Flag, "lteb4_sim", translate("LTE B4"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb13_sim", translate("LTE B13"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "AU" then
			o = s2:option(Flag, "gsm850_sim", translate("GSM850"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm900_sim", translate("GSM900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm1800_sim", translate("GSM1800"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "gsm1900_sim", translate("GSM1900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma850_sim", translate("WCDMA 850"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma900_sim", translate("WCDMA 900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma1900_sim", translate("WCDMA 1900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb2_sim", translate("LTE B2"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb4_sim", translate("LTE B4"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb5_sim", translate("LTE B5"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb7_sim", translate("LTE B7"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb8_sim", translate("LTE B8"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb28_sim", translate("LTE B28"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb40_sim", translate("LTE B40"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "AUT" then
			o = s2:option(Flag, "wcdma850_sim", translate("WCDMA 850"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb5_sim", translate("LTE B5"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb7_sim", translate("LTE B7"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb28_sim", translate("LTE B28"))
			o:depends("auto_sim", "disable")
		elseif modem_region == "J" then
			o = s2:option(Flag, "wcdma800_sim", translate("WCDMA 800"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma900_sim", translate("WCDMA 900"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "wcdma2100_sim", translate("WCDMA 2100"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb1_sim", translate("LTE B1"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb3_sim", translate("LTE B3"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb8_sim", translate("LTE B8"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb18_sim", translate("LTE B18"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb19_sim", translate("LTE B19"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb26_sim", translate("LTE B26"))
			o:depends("auto_sim", "disable")
			o = s2:option(Flag, "lteb41_sim", translate("LTE B41"))
			o:depends("auto_sim", "disable")
		end
	end

function calculate_gsmbandval(sim)
    local gsmbandval = 0x0
    local gsm900 = m:formvalue("cbid.simcard.bands.gsm900_"..sim) or ""
    local gsm1800 = m:formvalue("cbid.simcard.bands.gsm1800_"..sim) or ""
    local gsm850 = m:formvalue("cbid.simcard.bands.gsm850_"..sim) or ""
    local gsm1900 = m:formvalue("cbid.simcard.bands.gsm1900_"..sim) or ""

    if gsm900 == "1" then
        gsmbandval = gsmbandval + 0x1
    end
    if gsm1800 == "1" then
        gsmbandval = gsmbandval + 0x2
    end
    if gsm850 == "1" then
        gsmbandval = gsmbandval + 0x4
    end
    if gsm1900 == "1" then
        gsmbandval = gsmbandval + 0x8
    end

    return gsmbandval
end

function calculate_wcdmabandval(sim)
	local wcdmabandval = 0x0
	local wcdma2100 = m:formvalue("cbid.simcard.bands.wcdma2100_"..sim) or ""
	local wcdma1900 = m:formvalue("cbid.simcard.bands.wcdma1900_"..sim) or ""
	local wcdma850 = m:formvalue("cbid.simcard.bands.wcdma850_"..sim) or ""
	local wcdma900 = m:formvalue("cbid.simcard.bands.wcdma900_"..sim) or ""
	local wcdma800 = m:formvalue("cbid.simcard.bands.wcdma800_"..sim) or ""
	local wcdma1700 = m:formvalue("cbid.simcard.bands.wcdma1700_"..sim) or ""

	if wcdma2100 == "1" then
        wcdmabandval = wcdmabandval + 0x10
	end
	if wcdma1900 == "1" then
        wcdmabandval = wcdmabandval + 0x20
	end
	if wcdma850 == "1" then
        wcdmabandval = wcdmabandval + 0x40
	end
	if wcdma900 == "1" then
        wcdmabandval = wcdmabandval + 0x80
	end
	if wcdma800 == "1" then
        wcdmabandval = wcdmabandval + 0x100
	end
	if wcdma1700 == "1" then
        wcdmabandval = wcdmabandval + 0x200
	end

	return wcdmabandval
end

function calculate_ltebandval(sim)
	local ltebandval = 0x0
	local lteb1 = m:formvalue("cbid.simcard.bands.lteb1_"..sim) or ""
	local lteb2 = m:formvalue("cbid.simcard.bands.lteb2_"..sim) or ""
	local lteb3 = m:formvalue("cbid.simcard.bands.lteb3_"..sim) or ""
	local lteb4 = m:formvalue("cbid.simcard.bands.lteb4_"..sim) or ""
	local lteb5 = m:formvalue("cbid.simcard.bands.lteb5_"..sim) or ""
	local lteb7 = m:formvalue("cbid.simcard.bands.lteb7_"..sim) or ""
	local lteb8 = m:formvalue("cbid.simcard.bands.lteb8_"..sim) or ""
	local lteb12 = m:formvalue("cbid.simcard.bands.lteb12_"..sim) or ""
	local lteb13 = m:formvalue("cbid.simcard.bands.lteb13_"..sim) or ""
	local lteb18 = m:formvalue("cbid.simcard.bands.lteb18_"..sim) or ""
	local lteb19 = m:formvalue("cbid.simcard.bands.lteb19_"..sim) or ""
	local lteb20 = m:formvalue("cbid.simcard.bands.lteb20_"..sim) or ""
	local lteb26 = m:formvalue("cbid.simcard.bands.lteb26_"..sim) or ""
	local lteb28 = m:formvalue("cbid.simcard.bands.lteb28_"..sim) or ""
	local lteb38 = m:formvalue("cbid.simcard.bands.lteb38_"..sim) or ""
	local lteb40 = m:formvalue("cbid.simcard.bands.lteb40_"..sim) or ""
	local lteb41 = m:formvalue("cbid.simcard.bands.lteb41_"..sim) or ""

	if lteb1 == "1" then
		ltebandval = ltebandval + 0x1
	end
	if lteb2 == "1" then
		ltebandval = ltebandval + 0x2
	end
	if lteb3 == "1" then
		ltebandval = ltebandval + 0x4
	end
	if lteb4 == "1" then
		ltebandval = ltebandval + 0x8
	end
	if lteb5 == "1" then
		ltebandval = ltebandval + 0x10
	end
	if lteb7 == "1" then
		ltebandval = ltebandval + 0x40
	end
	if lteb8 == "1" then
		ltebandval = ltebandval + 0x80
	end
	if lteb12 == "1" then
		ltebandval = ltebandval + 0x800
	end
	if lteb13 == "1" then
		ltebandval = ltebandval + 0x1000
	end
	if lteb18 == "1" then
		ltebandval = ltebandval + 0x20000
	end
	if lteb19 == "1" then
		ltebandval = ltebandval + 0x40000
	end
	if lteb20 == "1" then
		ltebandval = ltebandval + 0x80000
	end
	if lteb26 == "1" then
		ltebandval = ltebandval + 0x2000000
	end
	if lteb28 == "1" then
		ltebandval = ltebandval + 0x8000000
	end
	if lteb38 == "1" then
		ltebandval = ltebandval + 0x2000000000
	end
	if lteb40 == "1" then
		ltebandval = ltebandval + 0x8000000000
	end
	if lteb41 == "1" then
		ltebandval = ltebandval + 0x10000000000
	end

	return dec_to_hex(ltebandval)
end

function dec_to_hex(dec)
	local b, k, out, i = 16, "0123456789ABCDEF", "", 0
	local d
	while dec > 0 do
		i = i + 1
		dec, d = math.floor(dec/b), math.mod(dec, b) + 1
		out = string.sub(k,d,d)..out
	end
	return out
end

function revert_bands(sim)
    m.uci:foreach("simcard", "bands", function(s)
        for key, value in pairs(s) do
            if key:find(sim) ~= nil and key:find("auto_sim") == nil then
                m.uci:delete("simcard", "bands", key)
                m.uci:save("simcard")
            end
        end
    end)
end

function m.on_commit(map)
		local sim1_passthrough = m:formvalue("cbid.simcard.sim1.passthrough_mode") or ""
		local mac_addr = m:formvalue("cbid.simcard.sim1.mac") or ""
		local sim1_proto = m:formvalue("cbid.simcard.sim1.proto") or ""
		if sim1_proto then
			m.uci:set("simcard", "sim1", "proto", "3g")
		end

		local sim1_method = m:formvalue("cbid.simcard.sim1.method") or ""
		if sim1_method == "pbridge" then
			local sim1_leasetime = m:formvalue("cbid.simcard.sim1.leasetime") or "12"
			local sim1_letter = m:formvalue("cbid.simcard.sim1.letter") or "h"
			m.uci:set("simcard", "sim1", "leasetime", sim1_leasetime..""..sim1_letter)
		end

		if sim1_passthrough == "dynamic" or sim1_passthrough == "no_dhcp" then
			m.uci:set("dhcp", "lan", "ignore", "1")
			m.uci:set("dhcp", "dhcp_relay", "enabled", "0")
			m.uci:save("dhcp")
			m.uci:commit("dhcp")
		end


		local demand_enable = m:formvalue("cbid.simcard.ppp.demand_enable") or ""
		local demand = m:formvalue("cbid.simcard.ppp.demand") or ""

		if demand_enable == "1" and demand ~= ""  then
				m.uci:set("network", "ppp", "demand", demand)
		elseif demand_enable ~= "1" then
				m.uci:delete("network", "ppp", "demand")
		end
		m.uci:save("network")
		m.uci:commit("network")

		if moduleVidPid == "2C7C:0125" or modulsevice == "QuectelLTE_EC25" then
            local service = m:formvalue("cbid.simcard.sim1.service") or ""
            local auto_sim = m:formvalue("cbid.simcard.bands.auto_sim") or ""
            local gsmbandval_sim, wcdmabandval_sim, bandval, ltebandval
            local auto_band = "0"
	    local ignore_band_match = false

            if auto_sim == "enable" then
                bandval = "ffff"
                ltebandval = "1a0000800d5"
            else
                gsmbandval_sim = calculate_gsmbandval("sim")
                wcdmabandval_sim = calculate_wcdmabandval("sim")
                ltebandval = calculate_ltebandval("sim")
                bandval = string.format("%x", gsmbandval_sim + wcdmabandval_sim)

		if gsmbandval_sim == 0 and wcdmabandval_sim == 0 and ltebandval == "0" then
			auto_band = "1"
		elseif service == "gprs-only" and gsmbandval_sim == 0 then
			m.message = "err:In 2G service mode you need to specify at least one GSM band. Connection method set to automatic."
			ignore_band_match = true
			bandval = "ffff"
			ltebandval = "1a0000800d5"
			auto_band = "1"
			revert_bands("sim")
		elseif service == "umts-only" and wcdmabandval_sim == 0 then
			m.message = "err:In 3G service mode you need to specify at least one WCDMA band. Connection method set to automatic."
			ignore_band_match = true
			bandval = "ffff"
			ltebandval = "1a0000800d5"
			auto_band = "1"
			revert_bands("sim")
		elseif service == "lte-only" and ltebandval == "0" then
			m.message = "err: In 4G service mode you need to specify at least one LTE band. Connection method set to automatic."
			ignore_band_match = true
			bandval = "ffff"
			ltebandval = "1a0000800d5"
			auto_band = "1"
			revert_bands("sim")
		end

		if not ignore_band_match and service == "grps-only" and (wcdmabandval_sim ~= 0 or ltebandval ~= "0") then
			m.message = "wrn: Using 3G (WCDMA) or 4G (LTE) bands with 2G (GSM) only service mode may cause network connectivity to become unstable."
		elseif not ignore_band_match and service == "umts-only" and (gsmbandval_sim ~= 0 or ltebandval ~= "0") then
			m.message = "wrn: Using 2G (GSM) or 4G (LTE) bands with 3G (WCDMA) only service mode may cause network connectivity to become unstable."
		elseif not ignore_band_match and service == "lte-only" and (gsmbandval_sim ~= 0 or wcdmabandval_sim ~= 0) then
			m.message = "wrn: Using 2G (GSM) or 3G (WCDMA) bands with 4G (LTE) only service mode may cause network connectivity to become unstable."
		end

                if bandval == "0" then
                    bandval = "ffff"
                end
                if ltebandval == "0" then
                    ltebandval = "1a0000800d5"
                end
            end

            if auto_band == "1" then
                m.uci:set("simcard", "bands", "auto_sim", "enable")
            end
            m.uci:set("simcard", "sim1", "bandval", bandval)
            m.uci:set("simcard", "sim1", "ltebandval", ltebandval)
		end
		m.uci:save("simcard")
end
if moduleVidPid == "12D1:1573" or moduleVidPid == "1BC7:1201" or moduleVidPid == "12D1:15C1" or moduleVidPid == "12D1:15C3" or modulsevice == "SieraLTE" or modulsevice == "QuectelLTE" or modulsevice == "TelitLTE_V2" or modulsevice == "QuectelLTE_EC25" then
	return m, m2
else
	return m
end

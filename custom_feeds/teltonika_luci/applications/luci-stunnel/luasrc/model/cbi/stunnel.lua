local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local util = require ("luci.util")

local m = Map("stunnel", translate("Stunnel"))

local globals = m:section( TypedSection, "globals", translate("Stunnel Globals"), translate("") )
globals.addremove = false

o = globals:option( Flag, "use_alt", translate("Use alternative config"), translate("Enable alternative configuration option (Config upload).<br> * Be aware that when using alternative configuration, all configurations in \"Stunnel Configuration\" section will be skipped"))

alt_config = globals:option( FileUpload, "alt_config_file", translate("Upload alternative config"), translate("ISAKMP (Internet Security Association and Key Management Protocol) phase 1 exchange mode"))
alt_config:depends("use_alt", "1")
alt_config.size = "51200"
alt_config.sizetext = translate("Selected file is too large. Maximum allowed size is 50 KiB")
alt_config.sizetextempty = translate("Selected file is empty")

local services = m:section( TypedSection, "service", translate("Stunnel Configuration"), translate("") )
services.addremove = true
services.template = "stunnel/tblsection"
services.novaluetext = translate("There are no STunnel configurations yet")
services.extedit = luci.dispatcher.build_url("admin", "services", "vpn", "stunnel", "%s")
services.defaults = {enabled = "0"}
services.sectionhead = "Name"


local status = services:option( Flag, "enabled", translate("Enabled"), translate("Make a stunnel active/inactive"))

ip_port = services:option( DummyValue, "accept_host", translate("Listening on"), translate("IP and port which server will be listening to"))

function ip_port.cfgvalue(self, section, value)
    local value = self.map:get(section, self.option)
    local port_value = self.map:get(section, "accept_port")

    if port_value and value then
        return value..":"..port_value
    else
        return "Not set"
    end
end

client = services:option( DummyValue, "client", translate("Operation mode"), translate("Stunnel operation mode. <br> * Server - Only listening on specified IP and Port. <br> * Client - Both listening and connecting to specified IPs"))

function client.cfgvalue(self, section, value)
    local value = self.map:get(section, self.option)

    if value and value == "1" then
        return "Client"
    elseif value and value == "0" then
        return "Server"
    else
        return "Not set"
    end
end

return m

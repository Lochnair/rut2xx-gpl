module("luci.controller.modbus", package.seeall)

function index()
  entry( { "admin", "services", "modbus" }, cbi("modbus"), _("Modbus"), 99)
end

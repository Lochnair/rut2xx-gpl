
m = Map("wget_reboot", translate("Wget Reboot"), translate(""))
s = m:section(NamedSection, "wget_reboot", translate("Wget Reboot"), translate("Wget Reboot Setup"))
s.addremove = false

-- enable wget reboot option
e = s:option(Flag, "enable", translate("Enable"), translate("Enable wget reboot feature"))

-- enable router reboot
v = s:option(ListValue, "action", translate("Action if response is received"), translate("Action after the defined number of unsuccessfull retries packet received"))
	v.template = "auto-reboot/lvalue"
	v:value("1", "Reboot")
	v:value("2", "Modem restart")
	v:value("3", "Restart mobile connection")
	v:value("4", "(Re)register")
	v:value("5", "None")

-- ping inverval column and number validation
t = s:option(ListValue, "time", translate("Interval between requests"), translate("Time interval in minutes between two requests"))
	t.template = "auto-reboot/time"
	--t:depends("enable", "1")
	t:value("1", translate("1 mins"))
	t:value("2", translate("2 mins"))
	t:value("3", translate("3 mins"))
	t:value("4", translate("4 mins"))
	t:value("5", translate("5 mins"))
	t:value("15", translate("15 mins"))
	t:value("30", translate("30 mins"))
	t:value("60", translate("1 hour"))
	t:value("120", translate("2 hours"))

l = s:option(Value, "timeout", translate("Wget timeout (sec)"), translate("Time interval (in seconds) wget wait responce. Range [1 - 9999]"))
l.default = "10"
l.datatype = "range(1,9999)"

-- number of retries and number validation
k = s:option(Value, "retry", translate("Retry count"), translate("Number of retries after unsuccessful to receive reply packets. Range [0 - 9999]"))
k.default = "2"
k.datatype = "range(0,9999)"

-- host ping from wired
l = s:option(Value, "host", translate("Host to ping"), translate("IP address or domain name which will be used to send packets to. E.g. www.google.com (or www.host.com if DNS server is configured correctly)"))
l.default = "www.google.com"
l.datatype = "url"

return m

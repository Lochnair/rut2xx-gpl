function start()

    local days={"mon", "tue", "wed", "thu", "fri", "sat", "sun" }
    local script = "/sbin/gpio.sh"
    local set = {}
    local clear = {}
    local pin_state = {}
    local cron
    local old_i

    os.execute("cat /etc/scheduler/config | cut -d':' -f 2 > /tmp/cron.tmp")
    local handle = io.open("/tmp/cron.tmp")

    j = 1
    for line in handle:lines() do
        n = 1
        for i in line:gmatch"." do
            if i == "1" then
                table.insert(set, "DOUT1")
                table.insert(clear, "DOUT2")
            elseif i == "2" then
                table.insert(set, "DOUT2")
                table.insert(clear, "DOUT1")
            elseif i == "3" then
                table.insert(set, "DOUT1")
                table.insert(set, "DOUT2")
            elseif i == "0" then
                table.insert(clear, "DOUT1")
                table.insert(clear, "DOUT2")
            end
            if old_i ~= i then
                cron_conf = io.open("/etc/crontabs/root", "a")

                for key, value in pairs(set) do
                    if pin_state[value] ~= 1 then
                        cron = string.format("0 %s * * %s %s set %s%s", n-1, days[j], script, value, "\n")
                        cron_conf:write(cron)
                        pin_state[value] = 1
                        empty = false
                    end
                    os.execute("logger " ..cron)
                end

                for key, value in pairs(clear) do
                    if pin_state[value] ~= 0 then
                        cron = string.format("0 %s * * %s %s clear %s%s", n-1, days[j], script, value, "\n")
                        cron_conf:write(cron)
                        pin_state[value] = 0
                    end
                    os.execute("logger " ..cron)
                end
                cron_conf:close()
            end
            n = n + 1
            old_i = i
            set = {}
            clear = {}
        end
        j = j + 1
    end
end

start()

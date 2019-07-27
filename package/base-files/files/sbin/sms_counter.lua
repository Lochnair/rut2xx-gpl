#!/usr/bin/env lua
local sqlite = require "lsqlite3"
local db -- database identifier

local dbPath = "/log/" -- place for running database
local dbName = "log.db" -- database file name
local dbFullPath = "/log/log.db" -- full path to database
local table_name = "SMS_COUNT"
local table_name_sms = "SMS_TABLE"



function failture()
	local out =
	[[ Wrong argument
		send	SLOT (SLOT1,SLOT2)
		recieve	SLOT (SLOT1,SLOT2)
		reset	SLOT (SLOT1,SLOT2,both)
		value	SLOT (SLOT1,SLOT2,both)
	]]
	print(out)
	db:close()
	os.exit()
end

function check_table()
	local query = "select count(*) as number from ".. table_name
-- 	local stmt = db:rows(query)

	--~ Papildomas tikrinimas ar sukurtos reiksmes. Kitaip veliau negali ju updatint
	for row in db:nrows(query) do
		if row.number == 0 then
			local query = "insert into SMS_COUNT (SLOT,SEND,RECIEVED) values ('SLOT1',0,0);insert into SMS_COUNT (SLOT,SEND,RECIEVED) values ('SLOT2',0,0)"
			db:exec(query)
			break
		end
	end

	--~ Papildymas sms counterio del sim switcho
	query = "select * from " .. table_name_sms
	stmt = db:prepare(query)
	if stmt == nil then
		query = "create table ".. table_name_sms .. " (ID INTEGER PRIMARY KEY AUTOINCREMENT, SIM char(15), SEND INTEGER, TIME INTEGER)"
		db:exec(query)
	end
end

function get_values(slot)
	if slot == "SLOT0" then
		slot = "SLOT2"
	end
	if slot == "SLOT1" or slot == "SLOT2" or slot =="both" then
		local query = ""
		if slot == "SLOT1" or slot == "SLOT2" then
			query = "select * from " .. table_name .." where SLOT='".. slot .."'"
		else
			query = "select * from " .. table_name
		end
		local list = {}
		for row in db:nrows(query) do
			list[#list+1] = row
		end
		if slot == "SLOT1" or slot == "SLOT2" then
			print(list[1].SEND .. " " .. list[1].RECIEVED )
		else
			print(list[1].SEND .. " " .. list[1].RECIEVED .. "\n" .. list[2].SEND .. " " .. list[2].RECIEVED)
		end
	else
		failture()
	end
end

function send(slot)
	if slot == "SLOT0" then
		slot = "SLOT2"
	end
	if slot == "SLOT1" or slot == "SLOT2" then
		local query = "select SEND from ".. table_name .." where SLOT='".. slot .."'"
		for row in db:nrows(query) do
				row.SEND = row.SEND + 1
				local query = "update " .. table_name .." set SEND=".. row.SEND .." where SLOT='".. slot .."'"
				db:exec(query)
		end
		--~ inserts sent sms from sim and time
		if slot == "SLOT1" then
			query = "INSERT INTO SMS_TABLE (SIM, SEND, TIME) VALUES ('SIM1', 1, "..os.time().."); "
		else
			query = "INSERT INTO SMS_TABLE (SIM, SEND, TIME) VALUES ('SIM2', 1, "..os.time().."); "
		end
		db:exec(query)
	else
		failture()
	end
end

function recieve(slot)
	if slot == "SLOT0" then
		slot = "SLOT2"
	end
	if slot == "SLOT1" or slot == "SLOT2" then
		local query = "select RECIEVED from SMS_COUNT where SLOT='".. slot .."'"
		for row in db:nrows(query) do
				row.RECIEVED = row.RECIEVED + 1
				local query = "update SMS_COUNT set RECIEVED=".. row.RECIEVED .." where SLOT='".. slot .."'"
				db:exec(query)
		end
		--~ inserts sent sms from sim and time
		if slot == "SLOT1" then
			query = "INSERT INTO SMS_TABLE (SIM, SEND, TIME) VALUES ('SIM1', 0, "..os.time().."); "
		else
			query = "INSERT INTO SMS_TABLE (SIM, SEND, TIME) VALUES ('SIM2', 0, "..os.time().."); "
		end
		db:exec(query)
	else
		failture()
	end

end

function reset(slot)
	if slot == "SLOT0" then
		slot = "SLOT2"
	end
	if slot == "SLOT1" or slot == "SLOT2" or slot =="both" then
		if slot == "SLOT1" or slot == "both" then
			local query = "update " .. table_name .." set SEND=0 where SLOT='".. slot .."'; update " .. table_name .." set RECIEVED=0 where SLOT='".. slot .."'"
			db:exec(query)
		end
		if slot == "SLOT2" or slot == "both" then
			local query = "update " .. table_name .." set SEND=0 where SLOT='".. slot .."'; update " .. table_name .." set RECIEVED=0 where SLOT='".. slot .."'"
			db:exec(query)
		end
	else
		failture()
	end
end

function start()

	if arg[1] and arg[2] then
		db = sqlite.open(dbFullPath)
		check_table()
		if arg[1] == "send" then
			send(arg[2])
		elseif arg[1] == "recieve" then
			recieve(arg[2])
		elseif arg[1] == "reset" then
			reset(arg[2])
		elseif arg[1] == "value" then
			get_values(arg[2])
		else
			failture()
		end
		db:close()
	else
		failture()
	end
end

start()




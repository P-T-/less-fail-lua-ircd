function admin_op(chan,cl)
	if not contains(chans[chan].op,cl) then
		sendchan(chan,":potato.lua MODE "..chan.." +o "..cl.nick)
		table.insert(chans[chan].op,cl)
	end
end
function admin_deop(chan,cl)
	if contains(chans[chan].op,cl) then
		sendchan(chan,":potato.lua MODE "..chan.." -o :"..cl.nick)
		table.vremove(chans[chan].op,cl)
	end
end
function admin_voice(chan,cl)
	if not contains(chans[chan].voice,cl) then
		sendchan(chan,":potato.lua MODE "..chan.." +v :"..cl.nick)
		table.insert(chans[chan].voice,cl)
	end
end
function admin_devoice(chan,cl)
	if contains(chans[chan].voice,cl) then
		sendchan(chan,":potato.lua MODE "..chan.." -v :"..cl.nick)
		table.vremove(chans[chan].voice,cl)
	end
end
hook.new("command_mode",function(cl,chan,mode,user)
	if not chan then
		return 461,"MODE","Not enough parameters"
	end
	if mode and user and nicks[user] and mode:match("^[%+%-][vo]$") then
		if contains((chans[chan] or {}).op or {},cl) then
			sendchan(chan,":"..cl.id.." MODE "..chan.." "..mode.." "..user)
			if mode=="+o" and not contains(chans[chan].op,nicks[user]) then
				table.insert(chans[chan].op,nicks[user])
			elseif mode=="+v" and not contains(chans[chan].voice,nicks[user]) then
				table.insert(chans[chan].voice,nicks[user])
			elseif mode=="-o" then
				table.vremove(chans[chan].op,nicks[user])
			elseif mode=="-v" then
				table.vremove(chans[chan].voice,nicks[user])
			end
		end
	end
end)
local function maxval(tbl)
	local mx=0
	for k,v in pairs(tbl) do
		if type(k)=="number" then
			mx=math.max(k,mx)
		end
	end
	return mx
end
hook.new("msg",function(cl,chan,txt)
	if cl.ip=="127.0.0.1" and txt:match("^@") then
		txt=txt:match("^@(.+)")
		local func,err=loadstring("return "..txt,"=lua")
		if not func then
			func,err=loadstring(txt,"=lua")
			if not func then
				sendchan(chan,":potato.lua PRIVMSG "..chan.." :"..err)
				return
			end
		end
		local res={xpcall(func,debug.traceback)}
		for l1=2,math.max(maxval(res),2) do
			sendchan(chan,":potato.lua PRIVMSG "..chan.." :"..tostring(res[l1]))
		end
	end
end)

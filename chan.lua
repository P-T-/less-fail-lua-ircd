chans={}
function sendchan(chan,txt,cl)
	cl=type(cl)=="table" and cl.nick or cl
	print(serialize({chan,txt,cl}))
	if type(chan)~="table" then
		chan={[chan]=true}
	end
	local r={}
	for k,v in pairs(chan) do
		for k,v in pairs(chans[k].users) do
			local u=nicks[k]
			if u and (not cl or k~=cl) and not r[k] then
				u:send(txt)
				r[k]=true
			end
		end
	end
end

function chan_join(user,chan)
	user=type(user)=="string" and nick[user] or user
	if type(chan)~="table" then
		chan={chan}
	end
	for k,v in pairs(chan) do
		chans[v]=chans[v] or {
			voice={},
			op={},
			ban={},
			quiet={},
			modes={},
			users={},
			name=v,
		}
		local nchan=chans[v]
		nchan.users[user.nick]=true
		user.chans[v]=true
		sendchan(v,":"..user.id.." JOIN "..v)
		local cchan={}
		for k,v in pairs(chans[v].users) do
			table.insert(cchan,k)
		end
		for l1=1,#cchan,50 do
			local o={}
			for l2=l1,l1+49 do
				if cchan[l2] then
					table.insert(o,(nchan.voice[cchan[l2]] and "+" or "")..(nchan.op[cchan[l2]] and "@" or "")..cchan[l2])
				end
			end
			user:send(encode(user,353,"=",v,":"..table.concat(o," ")))
		end
		user:send(encode(user,366,v,"End of /NAMES list."))
		if #cchan==1 then
			setmode(v,"+o",user,"potato.lua")
		end
	end
end

function chan_part(user,chan,txt)
	user=type(user)=="string" and nick[user] or user
	if type(chan)~="table" then
		chan={[chan]=true}
	end
	for k,v in pairs(chan) do
		if txt~=false then
			sendchan(k,":"..user.id.." PART "..k.." :"..(txt or "Leaving"))
		end
		user.chans[k]=nil
		chans[k].users[user.nick]=nil
		if not next(chans[k].users) then
			chans[k]=nil
		end
	end
end

hook.new("command_join",function(user,chans)
	if not chans then
		return 461,"JOIN","Not enough parameters"
	end
	local cchans={}
	for chan in chans:gmatch("[^,]+") do
		if chan:match("^#[%w%d]*$") then
			table.insert(cchans,chan)
		else
			user:send(encode(user,403,chan,"No such channel"))
		end
	end
	for k,v in pairs(cchans) do
		if not user.chans[v] then
			chan_join(user,v)
		end
	end
end)

hook.new("command_part",function(user,chan,txt)
	if not chan then
		return 461,"JOIN","Not enough parameters"
	elseif not chans[chan] then
		return 403,chan,"No such channel"
	elseif not user.chans[chan] then
		return 442,chan,"You're not on that channel"
	end
	chan_part(user,chan,txt)
end)

hook.new("command_privmsg",function(user,chan,txt)
	if not chan or not txt then
		return 461,"PRIVMSG","Not enough parameters"
	end
	if chans[chan] then
		if user.chans[chan] then
			sendchan(chan,":"..user.id.." PRIVMSG "..chan.." :"..txt,user)
			hook.queue("msg",user,chan,txt)
		else
			return 404,chan,"Cannot send to channel"
		end
	elseif nicks[chan] then
		nicks[chan]:send(":"..user.id.." PRIVMSG "..chan.." :"..txt)
		hook.queue("msg",user,chan,txt)
	else
		return 401,chan,"No such nick/channel"
	end
end)

hook.new("command_notice",function(user,chan,txt)
	if not chan or not txt then
		return 461,"NOTICE","Not enough parameters"
	end
	if chans[chan] then
		if user.chans[chan] then
			sendchan(chan,":"..user.id.." NOTICE "..chan.." :"..txt,user)
			hook.queue("notice",user,chan,txt)
		else
			return 404,chan,"Cannot send to channel"
		end
	elseif nicks[chan] then
		nicks[chan]:send(":"..user.id.." NOTICE "..chan.." :"..txt)
		hook.queue("notice",user,chan,txt)
	else
		return 401,chan,"No such nick/channel"
	end
end)

hook.new("command_quit",function(user,reason)	
	if reason then
		user:close("Client quit ("..reason..")")
	else
		user:close("Client quit")
	end
end)

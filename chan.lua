chans={}
function sendchan(chan,txt,cl)
	cl=type(cl)=="table" and cl.nick or cl
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
		}
		local nchan=chans[v]
		nchan.users[user.nick]=true
		user.chans[v]=true
		sendchan(v,":"..cl.nick.." JOIN "..v)
		local cchan={}
		for k,v in pairs(chans[v].users) do
			table.insert(cchan,k)
		end
		for l1=1,#cchan,50 do
			local o={}
			for l2=l1,l1+49 do
				if cchan[l2] then
					table.insert(o,nchan.voice[cchan[l2]] and "+" or "")..(nchan.op[cchan[l2]] and "@" or "")..cchan[l2]
				end
			end
			user:send(encode(cl,353,"=",v,":"..table.concat(o," ")))
		end
		user:send(encode(cl,366,v,"End of /NAMES list."))
		if #cchan==1 then
			admin_op(v,cl)
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
			sendchan(k,":"..user.nick.." PART "..k.." :"..(txt or "Leaving"))
		end
		cl.chans[k]=nil
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
		if chan:match("^#[%w%d]*$") then
			if not cl.chans[chan] then
				chan_join(cl,chan)
			end
		else
			return 403,chan,"No such channel"
		end
	end
end)

hook.new("command_part",function(cl,chan,txt)
	if not chan then
		return 461,"JOIN","Not enough parameters"
	elseif not chans[chan] then
		return 403,chan,"No such channel"
	elseif not cl.chans[chan] then
		return 442,chan,"You're not on that channel"
	elseif chan~="#oc" then
		chan_part(cl,chan,txt)
	end
end)

hook.new("command_privmsg",function(user,chan,txt)
	if not chan or not txt then
		return 461,"PRIVMSG","Not enough parameters"
	end
	if chans[chan] then
		if cl.chans[chan] then
			sendchan(chan,":"..user.nick.." PRIVMSG "..chan.." :"..txt,user)
			hook.queue("msg",user,chan,txt)
		else
			return 404,chan,"Cannot send to channel"
		end
	elseif nicks[chan] then
		nicks[chan]:send(":"..user.nick.." PRIVMSG "..chan.." :"..txt)
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
		if cl.chans[chan] then
			sendchan(chan,":"..user.nick.." NOTICE "..chan.." :"..txt,user)
			hook.queue("notice",user,chan,txt)
		else
			return 404,chan,"Cannot send to channel"
		end
	elseif nicks[chan] then
		nicks[chan]:send(":"..user.nick.." NOTICE "..chan.." :"..txt)
		hook.queue("notice",user,chan,txt)
	else
		return 401,chan,"No such nick/channel"
	end
end)

hook.new("command_quit",function(user,reason)
	for k,v in pairs(user,chans) do
		chan_part(user,k,false)
		sendchan()
	end
	if reason then
		user.cl:close("Client quit ("..reason..")")
	else
		user.cl:close("Client quit")
	end
end)

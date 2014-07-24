local smode={
	v="voice",
	o="op",
	q="quiet",
	b="ban",
}
local cmode={
	
}
function setmode(chan,mode,cl)
	chan=chans[chan]
	local cm=mode:sub(1,1)=="+"
	mode=mode:sub(2)
	if cl then
		chan[smode[mode]][cl]=cm or nil
	else
		chan.modes[mode]=cm or nil
	end
end
hook.new("command_mode",function(cl,schan,modes,...)
	local chan=chans[schan]
	if not modes then
		return 461,"MODE","Not enough parameters"
	elseif not chan then
		return 403,schan,"No such channel"
	elseif not chan.op[cl.nick] then
		return 482,schan,"You're not a channel operator"
	end
	local users={...}
	local cm=true
	local md={}
	for l1=1,#modes do
		local c=modes:sub(l1,l1)
		if c=="+" or cm=="-" then
			cm=cm=="+"
		else
			md[#md+1]={c,cm}
		end
	end
	local om="+"
	local ou={}
	local cm=true
	for k,v in pairs(md) do
		if (smode[v[1]] or cmode[v[1]]) and cm~=v[2] then
			om=om..(cm and "-" or "+")
			cm=v[2]
		end
		if smode[v[1]] then
			local u=users[1]
			if u and nicks[u] then
				if not chan.users[u] then
					return 401,u,"No such nick/channel"
				end
				om=om..v[1]
				table.insert(ou,nicks[u])
				table.remove(users,1)
				setmode(chan,(cm and "+" or "-")..v[1],u)
			end
		elseif cmode[v[1]] then
			setmode(chan,(cm and "+" or "-")..v[1])
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
	if cl.sk:getpeername()=="127.0.0.1" and txt:match("^@") then
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

hook.new("command_cloak",function(cl,user,host)
	user=nicks[user]
	if user then
		sendchan(user.chans,":"..user.id.." QUIT :Changing hosts",user)
		user.ip=host
		user.id=user.nick.."!"..user.username.."@"..user.ip
		for k,v in pairs(user.chans) do
			sendchan(v,":"..user.id.." JOIN "..v,user)
		end
	end
end)


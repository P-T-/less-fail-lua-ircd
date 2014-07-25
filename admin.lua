local smode={
	v="voice",
	o="op",
	q="quiet",
	b="ban",
}
local cmode={
	
}
function setmode(chan,tmode,cl,ru)
	chan=type(chan)=="string" and chans[chan] or chan
	local cm=tmode:sub(1,1)=="+"
	local mode=tmode:sub(2)
	if cl then
		cl=type(cl)=="string" and nicks[cl] or cl
		if ru then
			sendchan(chan.name,":"..ru.." MODE "..chan.name.." "..tmode.." "..cl.nick)
		end
		chan[smode[mode]][cl.nick]=cm or nil
	else
		chan.modes[mode]=cm or nil
	end
end
hook.new("command_mode",function(user,schan,modes,...)
	local chan=chans[schan]
	if not schan or schan=="" then
		return 461,"MODE","Not enough parameters"
	elseif not chan then
		return 403,schan,"No such channel"
	elseif not modes or modes=="" then
		local o="+"
		for k,v in pairs(chan.modes) do
			o=o..k
		end
		return 324,chan.name,o
	elseif not chan.op[user.nick] then
		return 482,schan,"You're not a channel operator"
	end
	local users={...}
	local cm=true
	local md={}
	for l1=1,#modes do
		local c=modes:sub(l1,l1)
		if c=="+" or c=="-" then
			cm=c=="+"
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
				table.insert(ou,u)
				table.remove(users,1)
				setmode(chan,(cm and "+" or "-")..v[1],u)
			end
		elseif cmode[v[1]] then
			setmode(chan,(cm and "+" or "-")..v[1])
		end
	end
	om=om:gsub("%+%-","-")
	if #om>1 then
		sendchan(chan.name,":"..user.id.." MODE "..chan.name.." "..om.." "..table.concat(ou," "))
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
		txt=txt:match("^@(.*)")
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


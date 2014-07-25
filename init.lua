function encode(user,code,...)
	local p={...}
	if (p[#p] or ""):match("%s") then
		p[#p]=":"..p[#p]:gsub("^:?","")
	end
	if type(code)=="number" then
		code=tostring(code)
		code=("0"):rep(math.max(0,3-#code))..code
	end
	return ":potato.lua "..code.." "..(user.nick or "*").." "..table.concat(p," ")
end

hook.new("raw",function(user,txt)
	local cmd,params=txt:match("^(%S*)%s?(.*)")
	print("got command "..cmd)
	cmd=cmd:lower()
	if user.connected or cmd=="nick" or cmd=="user" then
		local long=params:match("%s:(.+)")
		if long then
			params=params:gsub("%s:.*","")
		end
		local pr={}
		for item in params:gmatch("%S+") do
			table.insert(pr,item)
		end
		if long then
			table.insert(pr,long)
		end
		print("params: "..params.." :"..(long or ""))
		hook.callback=function(...)
			if ... then
				user:send(encode(user,...))
			end
		end
		hook.queue("command_"..cmd,user,unpack(pr))
		hook.queue("command",cmd,user,unpack(pr))
	elseif cmd=="quit" then
		user:close()
	end
end)

hook.new("command_user",function(user,username,_,_,realname)
	if not user.connected then
		if not username and not realname then
			return 461,"USER","Not enough parameters"
		end
		user.username=username:gsub("[^%a%d]",""):sub(1,8)
		user.realname=realname
		if user.nick then
			hook.queue("connect",user)
		end
	else
		return 462,"You may not reregister"
	end
end)

function validnick(nick)
	return nick:match("^[%a%^_\\|%[%]][%a%d%^_\\|%[%]]*$") and #nick<17
end

hook.new("command_nick",function(user,nick)
	if not nick then
		return 461,"NICK","Not enough parameters"
	elseif nicks[nick] then
		return 433,nick,"Nickname is already in use"
	elseif not validnick(nick) then
		return 432,nick,"Erroneous Nickname"
	end
	if user.nick then
		nicks[user.nick]=nil
	end
	local onick=user.nick
	nicks[nick]=user
	user.nick=nick
	if not user.connected and user.username then
		hook.queue("connect",user)
	elseif user.username then
		sendchan(user.chans,":"..user.id.." NICK "..nick)
		user.id=user.nick.."!"..user.username.."@"..user.ip
	end
end)

hook.new("connect",function(user)
	user.id=user.nick.."!"..user.username.."@"..user.ip
	user.connected=true
	user:send(encode(user,001,"Welcome to my fail irc server "..user.nick))
	user:send(encode(user,002,"Your host is potato.lua[71.238.153.166/6667], running FailLuaIRCd version 0.0-0"))
	user:send(encode(user,003,"This server was created Jan 1 0000 at 00:00:00 UTC"))
	user:send(encode(user,004,"potato.lua","FailLuaIRCd0.0-0","DQRSZagiloswz","CFILPQbcefgijklmnopqrstvz","bkloveqjfI"))
	user:send(encode(user,005,"CHANTYPES=#","EXCEPTS","INVEX","CHANMODES=eIbq,k,flj,CFPcgimnpstz","CHANLIMIT=#:50","PREFIX=(ov)@+","MAXLIST=bqeI:100","MODES=4","NETWORK=PotatoNet","KNOCK","STATUSMSG=@+","CALLERID=g","are supported by this server"))
	user:send(encode(user,005,"CASEMAPPING=rfc1459","CHARSET=ascii","NICKLEN=16","CHANNELLEN=50","TOPIuserEN=390","ETRACE","CPRIVMSG","CNOTICE","DEAF=D","MONITOR=100","FNC","TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:","are supported by this server"))
	user:send(encode(user,005,"EXTBAN=$,acjorsxz","WHOX","userIENTVER=3.0","SAFELIST ELIST=CTU","are supported by this server"))
	user:send(encode(user,251,"There are 1337 users and 1337 invisible on 1337 servers"))
	user:send(encode(user,252,1337,"IRC Operators online"))
	user:send(encode(user,253,1337,"unknown connection(s)"))
	user:send(encode(user,254,1337,"channels formed"))
	user:send(encode(user,255,"I have 1337 userients and 1337 servers"))
	user:send(encode(user,265,1337,1337,"Current local users 1337, max 1337"))
	user:send(encode(user,266,1337,1337,"Current global users 1337, max 1337"))
	user:send(encode(user,250,"Highest connection count: 1337 (1337 userients) (1337 connections received)"))
	user:send(encode(user,375,"- potato Message of the Day -"))
	user:send(encode(user,372,"  ______    o            _____ "))
	user:send(encode(user,372," |      |  _    |\\    | |      "))
	user:send(encode(user,372," |      |   |   | \\   | |      "))
	user:send(encode(user,372," |______|   |   |  \\  | |  ___ "))
	user:send(encode(user,372," |          |   |   \\ | |     |"))
	user:send(encode(user,372," |        __|__ |    \\| |_____|"))
	user:send(encode(user,376,"End of /MOTD command."))
	user:send(":"..user.nick.." MODE "..user.nick.." :+i")
	chan_join(user,"#oc")
end)


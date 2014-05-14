local socket=require("socket")
function tpairs(tbl)
	local s={}
	local c=1
	for k,v in pairs(tbl) do
		s[c]=k
		c=c+1
	end
	c=0
	return function()
		c=c+1
		return s[c],tbl[s[c]]
	end
end
dofile("C:\\A\\ocbot\\hook.lua")
dofile("init.lua")
dofile("chan.lua")
dofile("ping.lua")
dofile("admin.lua")
dofile("serialize.lua")
local sv=assert(socket.bind("*",6667))
hook.newsocket(sv)
clients={}
nicks={}
local function send(cl,txt)
	print("SENDING "..cl.ip.." \""..txt.."\"")
	return cl.sk:send(txt.."\r\n")
end
local function close(cl,reason)
	if cl.nick then
		sendchan(cl.chans,":"..cl.id.." QUIT :"..(reason or "Quit"),true)
		for k,v in pairs(cl,chans) do
			chans[v]=chans[v] or {}
			table.vremove(chans[v],cl)
			if #chans[v] then
				chans[v]=nil
			end
		end
		nicks[cl.nick]=nil
	end
	cl.sk:close()
	clients[cl.sk]=nil
	hook.remsocket(cl.sk)
end
function table.vremove(tbl,val)
	for k,v in pairs(tbl) do
		if v==val then
			table.remove(tbl,k)
			break
		end
	end
end
function contains(tbl,val)
	for k,v in pairs(tbl) do
		if v==val then
			return true
		end
	end
	return false
end
while true do
	local cl=sv:accept()
	while cl do
		hook.newsocket(cl)
		clients[cl]={
			sk=cl,
			ip=cl:getpeername(),
			send=send,
			close=close,
			chans={},
		}
		hook.queue("new_client",clients[cl])
		cl=sv:accept()
	end
	for k,v in tpairs(clients) do
		if v then
			local res,err=k:receive(0)
			if err and err~="timeout" then
				close(v,"Socket error")
			else
				local txt=k:receive()
				if txt then
					hook.queue("raw",v,txt:sub(1,256))
				end
			end
		end
	end
	hook.queue("select",socket.select(hook.sel,hook.rsel,math.min(5,hook.interval or 5)))
end
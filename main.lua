socket=require("socket")
dofile("hook.lua")
dofile("init.lua")
dofile("chan.lua")
dofile("ping.lua")
dofile("admin.lua")
dofile("who.lua")
dofile("serialize.lua")
dofile("async.lua")
local sv=assert(socket.bind("*",6667))
hook.newsocket(sv)
clients={}
nicks=setmetatable({},{__index=function(s,n)
	for k,v in pairs(nicks) do
		if k:lower()==n:lower() then
			return v
		end
	end
end})
local function send(cl,txt)
	async.new(function()
		async.socket(cl.sk).send(txt.."\r\n")
	end)
end
local function close(cl,reason)
	if cl.nick then
		sendchan(cl.chans,":"..cl.id.." QUIT :"..(reason or "Quit"))
		chan_part(cl,cl.chans,false)
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
			buffer={},
		}
		hook.queue("new_client",clients[cl])
		cl=sv:accept()
	end
	for k,v in tpairs(clients) do
		if v then
			local res,err=k:receive(0)
			if err and err~="timeout" then
				close(v,"Error: "..err)
			else
				local txt=k:receive()
				if txt then
					hook.queue("raw",v,txt:sub(1,512))
				end
			end
		end
	end
	hook.queue("select",socket.select(hook.sel,hook.rsel,math.min(5,hook.interval or 5)))
end

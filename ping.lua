hook.new("command_ping",function(user,txt)
	if not txt then
		return 461,"PING","Not enough parameters"
	end
	return "PONG",":"..txt
end)

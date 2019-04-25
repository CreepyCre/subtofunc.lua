function subtofunc(subto, subscriber, post, priority)
	if _G[subto] == nil then
		return
	elseif subscriptions[subto] == nil then
		subscriptions[subto] = {{}, {}, _G[subto]}
		_G[subto] = function(...)
			local source = debug.getinfo(2).source
			local line = debug.getinfo(2).currentline
			local locals = {}
			local index = 1
			while (debug.getlocal(2, index)  ~= nil) do
				local k, v = debug.getlocal(2, index)
				locals[k] = v
				index = index + 1
			end
			local preevent = Event:new{source = source, line = line, locals = locals}
			runpresubs(subto, preevent, ...)
			local returnholder
			if (not preevent.canceloriginal) then
				returnholder = subscriptions[subto][3](...)
			end
			local postevent = Event:new{source = source, line = line, locals = locals}
			if (preevent.returnholder == nil) then postevent.returnholder = returnholder
			else postevent.returnholder = preevent.returnholder end
			runpostsubs(subto, postevent, ...)
			return postevent.returnholder
		end
	end
	if not post then
		subscriptions[subto][1][#subscriptions[subto][1] + 1] = {subscriber, priority}
		sortnewsub(subscriptions[subto][1])
	else
		subscriptions[subto][2][#subscriptions[subto][2] + 1] = {subscriber, priority}
		sortnewsub(subscriptions[subto][2])
	end
end

function unsub(subbedto, subscriber, post)
	local subtable = post and subscriptions[subbedto][2] or subscriptions[subbedto][1]
	local index = 1
	while (index <= #subtable) do
		if (subtable[index][1] == subscriber) then
			table.remove(subtable, index)
		else
			index = index + 1
		end
	end
end

function sortnewsub(sublist)
	for i = #sublist, 1, -1 do
		if sublist[i][2] > sublist[#sublist][2] and (i == 1 or sublist[i-1][2] <= sublist[#sublist][2]) then
			local temp = sublist[i]
			sublist[i] = sublist[#sublist]
			for n = i + 1, #sublist, 1 do
				sublist[n], temp = temp, sublist[n]
			end
			return
		end
	end
end

function runpresubs(subto, preevent, ...)
	for i,f in ipairs(subscriptions[subto][1]) do f[1](preevent, ...) end
end

function runpostsubs(subto, postevent, ...)
	for i,f in ipairs(subscriptions[subto][2]) do f[1](postevent, ...) end
end

function getoriginal(funcname)
	if subscriptions[funcname] == nil then
		return _G[funcname]
	else
		return subscriptions[funcname][3]
	end
end
subscriptions = {}



Event = {canceled = false, canceloriginal = false, source = nil, line = nil, locals = nil, returnholder = nil}

function Event:new(o)
	o = o or {}
    return o
end
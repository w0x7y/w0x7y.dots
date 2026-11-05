-- vis-autoclose: an opening bracket or quote types its closing one too
require('vis')

local close_of = { ['('] = ')', ['{'] = '}', ['['] = ']', ['<'] = '>', ["'"] = "'", ['"'] = '"', ['`'] = '`' }
local closing = {}
for _, close in pairs(close_of) do
	closing[close] = true
end

vis.events.subscribe(vis.events.INPUT, function(key)
	local after = vis.win.file:content(vis.win.selection.pos, 1)
	if key == after and closing[after] then -- step over the closing one
		vis:feedkeys('<Right>')
		return true
	end
	-- pair only before a space, a newline or a bracket
	if close_of[key] and (after == ' ' or after == '\n' or close_of[after] or closing[after]) then
		vis:insert(key .. close_of[key])
		vis:feedkeys('<Left>')
		return true
	end
	return false
end)

vis:map(vis.modes.INSERT, "<Backspace>", function()
	local cursor = vis.win.selection.pos
	if cursor == 0 then
		return 1
	end
	local prev = vis.win.file:content(cursor - 1, 2)
	-- Workaround until https://github.com/martanne/vis/issues/739 is solved
	vis:feedkeys("<Left>")
	if prev and close_of[prev:sub(1, 1)] == prev:sub(2, 2) then -- an empty pair goes whole
		vis:feedkeys("<Delete>")
	end
	vis:feedkeys("<Delete>")
	return 1
end, "Removes the previous character (and closed brackets, if empty)")

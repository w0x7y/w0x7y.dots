-- vis-modal: the status line, colored by mode
local style = require('plugins/style-compat') -- Local patch: styles on vis after 0.9

local M = {}

local MODAL_STYLE = style.id(51)
local MODAL_STYLE_INVERTED = style.id(52)

local MODES = {
	[vis.modes.NORMAL] = ' NORMAL ',
	[vis.modes.INSERT] = ' INSERT ',
	[vis.modes.VISUAL] = ' VISUAL ',
	[vis.modes.REPLACE] = ' REPLACE ',
	[vis.modes.VISUAL_LINE] = ' VISUAL_LINE ',
	[vis.modes.OPERATOR_PENDING] = ' OPERATOR_PENDING ',
}

local STYLES = {
	[vis.modes.NORMAL] = {
		REGULAR = 'fore:default,back:yellow',
		INVERTED = 'fore:yellow,back:black',
	},
	[vis.modes.INSERT] = {
		REGULAR = 'fore:default,back:green',
		INVERTED = 'fore:green,back:black',
	},
	[vis.modes.VISUAL] = {
		REGULAR = 'fore:default,back:magenta',
		INVERTED = 'fore:magenta,back:black',
	},
	[vis.modes.REPLACE] = {
		REGULAR = 'fore:default,back:blue',
		INVERTED = 'fore:blue,back:black',
	},
	[vis.modes.VISUAL_LINE] = {
		REGULAR = 'fore:default,back:magenta',
		INVERTED = 'fore:magenta,back:black',
	},
	[vis.modes.OPERATOR_PENDING] = {
		REGULAR = 'fore:default,back:blue',
		INVERTED = 'fore:blue,back:black',
	},
	UNFOCUSED = {
		REGULAR = 'fore:default,back:white',
		INVERTED = 'fore:white,back:black',
	},
}
M.STYLES = STYLES

-- Local patch: segments after the file name (M.left) and before line:col (M.right),
-- each a function(win) returning { text, style } parts. Left ones get cut to fit
M.left, M.right = {}, {}
-- Local patch: M.name(win) may rename the file, as vis-oil does
M.name = nil
local EXTRA_STYLE = style.id(53)

local function width(s)
	return utf8.len(s) or #s
end

local function cut(s, n)
	local stop = utf8.len(s) and utf8.offset(s, n + 1)
	return stop and s:sub(1, stop - 1) or s:sub(1, n)
end

local function parts_of(list, win)
	local parts = {}
	for _, fn in ipairs(list) do
		for _, part in ipairs(fn(win) or {}) do
			parts[#parts + 1] = part
		end
	end
	return parts
end

vis.events.subscribe(vis.events.WIN_STATUS, function(win)
	local filename = ' '..((M.name and M.name(win)) or win.file.name or '[NO NAME]')..(win.file.modified and ' *' or '')..' '
	local vmode = MODES[vis.mode]

	-- Local patch: mode, file, M.left, M.right, line:col
	local styled = {} -- { first cell, text, style }
	local right = ''
	for _, part in ipairs(parts_of(M.right, win)) do
		styled[#styled + 1] = { width(right), part[1], part[2] }
		right = right..part[1]
	end
	right = right..win.selection.line..":"..win.selection.col
	local right_start = win.width - width(right)
	for _, s in ipairs(styled) do
		s[1] = s[1] + right_start
	end

	local left = vmode..filename
	local room = right_start - width(left) - 1
	for _, part in ipairs(parts_of(M.left, win)) do
		local text = part[1]
		if width(text) > room then
			text = room > 1 and cut(text, room - 1)..'…' or ''
		end
		if text == '' then break end
		styled[#styled + 1] = { width(left), text, part[2] }
		left = left..text
		room = room - width(text)
	end
	win:status(left, right)

	-- Local patch: later vis shares styles between windows, so define this one's
	local colors = win == vis.win and STYLES[vis.mode] or STYLES.UNFOCUSED
	style.define(win, MODAL_STYLE, colors.REGULAR)
	style.define(win, MODAL_STYLE_INVERTED, colors.INVERTED)

	for i=0,win.width do
		win:style_pos(MODAL_STYLE, i, win.height - 1)
	end
	for i = width(vmode), width(vmode) + width(filename) - 1 do
		win:style_pos(MODAL_STYLE_INVERTED, i, win.height - 1)
	end

	for _, s in ipairs(styled) do
		if s[3] then
			style.define(win, EXTRA_STYLE, s[3]) -- style_pos copies it, so one id serves all
			for i = s[1], s[1] + width(s[2]) - 1 do
				win:style_pos(EXTRA_STYLE, i, win.height - 1)
			end
		end
	end
end)

return M

-- vis-colorizer: #rrggbb colors drawn on their own color

-- Local patch: one id, redefined per color: applying a style copies it into the cells
local style_compat = require('plugins/style-compat')
local STYLE = style_compat.id(64)

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
	local offset = win.viewport.bytes.start
	for starts, hex, after in win.file:content(win.viewport.bytes):gmatch("()#(%x+)()") do
		if #hex == 6 then
			local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
			-- Local patch: #010101, as vis 0.9 can't show #000000 with changecolors
			local fg = r * 30 + g * 59 + b * 11 > 12000 and "#010101" or "#ffffff"
			if not style_compat.define(win, STYLE, "fore:" .. fg .. ",back:#" .. hex) then
				break
			end
			win:style(STYLE, offset + starts - 1, offset + after - 2)
		end
	end
end)

-- vis-colorizer: hex colors drawn on their own color
local M = {
  text_colors = {
    dark = "#000000",
    light = "#ffffff"
  },
  six = true, -- #rrggbb
  three = false, -- #rgb
}

-- Local patch: one style id, from vis.ui after vis 0.9 (UI_STYLE_LEXER_MAX on 0.9).
-- vis copies a style into the cells when it is applied, so each color redefines it
local style_compat = require('plugins/style-compat')
local STYLE = style_compat.id(64)

M.extract_hex_colors = function(text)
	local matches = {}
	for starts, hex, after in text:gmatch("()#(%x+)()") do
		if (#hex == 3 and M.three) or (#hex == 6 and M.six) then
			matches[#matches + 1] = { starts = starts, ends = after - 1, hex = hex }
		end
	end
	return matches
end

M.draw = function(win, colors)
	local offset = win.viewport.bytes.start
	for _, color in ipairs(colors) do
		local hex = #color.hex == 3 and color.hex:gsub("%x", "%0%0") or color.hex
		local r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
		local fg = r * 30 + g * 59 + b * 11 > 12000 and M.text_colors.dark or M.text_colors.light

		-- Local patch: with changecolors vis 0.9 shows #000000 in a palette slot
		-- it never set up, so ask for #010101
		local style = ("fore:" .. fg .. ",back:#" .. hex):gsub("#000000", "#010101")
		if not style_compat.define(win, STYLE, style) then
			break
		end
		win:style(STYLE, color.starts - 1 + offset, color.ends - 1 + offset)
	end
end

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
	M.draw(win, M.extract_hex_colors(win.file:content(win.viewport.bytes)))
end)

return M

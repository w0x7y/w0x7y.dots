-- vis-cursor: the terminal's cursor takes the mode's shape, as in Neovim.
-- vis paints the cursor as a cell; this shows the terminal's own cursor instead,
-- which vis already moves to the primary cursor. Needs a vis build after 0.9
local M = {}

-- DECSCUSR shapes: 2 block, 4 underline, 6 bar
M.shapes = {
  [vis.modes.NORMAL] = 2,
  [vis.modes.INSERT] = 6,
  [vis.modes.VISUAL] = 4,
  [vis.modes.VISUAL_LINE] = 4,
  [vis.modes.REPLACE] = 4,
  [vis.modes.OPERATOR_PENDING] = 4,
}

local ui = vis.ui
if not ui.style_ids then -- vis 0.9 doesn't move the terminal's cursor
  return M
end

local function send(s)
  io.stderr:write(s) -- vis draws on stderr
  io.stderr:flush()
end

-- Stops painting the cursor cell. Every redraw, since :set theme redefines it
vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function()
  ui:style_define(ui.style_ids.CURSOR_PRIMARY, "keep_attribute")
end)

-- Every frame: curses hides the cursor again after a shell command
vis.events.subscribe(vis.events.UI_DRAW, function()
  send("\27[?25h\27[" .. (M.shapes[vis.mode] or 2) .. " q")
end)

vis.events.subscribe(vis.events.QUIT, function()
  send("\27[0 q") -- the terminal's own shape
end)

return M

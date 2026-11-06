-- Styles on vis 0.9 (per window, fixed ids) and later (in vis.ui, free ids)
local ui = vis.ui

local M = {}

-- A free style id, or fallback on vis 0.9
function M.id(fallback)
  return ui.style_push and ui:style_push() or fallback
end

-- Shared between windows on later vis, which is fine: applying a style copies it
function M.define(win, id, style)
  if ui.style_define then
    return ui:style_define(id, style)
  end
  return win:style_define(id, style)
end

return M

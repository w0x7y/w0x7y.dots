-- Styles on vis 0.9 and later. 0.9 defines them per window with fixed ids;
-- later vis defines them in vis.ui and hands out free ids
local ui = vis.ui

local M = {}

-- A free style id, or fallback on vis 0.9
function M.id(fallback)
  return ui.style_push and ui:style_push() or fallback
end

-- Later vis shares the style between windows, which is fine: applying a style
-- copies it into the cells
function M.define(win, id, style)
  if ui.style_define then
    return ui:style_define(id, style)
  end
  return win:style_define(id, style)
end

return M

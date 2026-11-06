-- Diagnostics on the status line: the cursor line's problem and the file's totals
local lspc = require("plugins/vis-lspc")
local modal = require("plugins/vis-modal")

local M = {}

-- Indexed by LSP severity
local NAMES = { "error", "warning", "info", "hint" }
local LETTERS = { "E", "W", "I", "H" }

-- message: the cursor line's problem, count: a total, gap: between totals
M.styles = {
  message = { "fore:red", "fore:yellow", "fore:blue", "fore:cyan" },
  count = { "fore:red", "fore:yellow", "fore:blue", "fore:cyan" },
  gap = "",
}

-- A file's diagnostics from all its servers
local function diagnostics(file)
  local open = file and file.path and lspc.open_files[file.path]
  local all = {}
  for _, list in pairs(open and open.diagnostics or {}) do
    for _, diagnostic in ipairs(list) do
      all[#all + 1] = diagnostic
    end
  end
  return all
end

local function severity(diagnostic)
  local s = diagnostic.severity
  return NAMES[s] and s or 1 -- lspc treats a missing severity as an error too
end

-- vis lines start at 1, LSP lines at 0. A range ending at column 0 stops before that line
local function covers(diagnostic, line)
  local first, last = diagnostic.range.start, diagnostic.range["end"]
  local stop = (last.character == 0 and last.line > first.line) and last.line - 1 or last.line
  return first.line <= line - 1 and line - 1 <= stop
end

-- More severe first, then further left
local function worse(a, b)
  local sa, sb = severity(a), severity(b)
  return sa < sb or (sa == sb and a.range.start.character < b.range.start.character)
end

-- The worst problem on a line and how many others it has
local function at_line(file, line)
  local worst, count = nil, 0
  for _, diagnostic in ipairs(diagnostics(file)) do
    if covers(diagnostic, line) then
      count = count + 1
      if not worst or worse(diagnostic, worst) then
        worst = diagnostic
      end
    end
  end
  return worst, count - 1
end

local function counts(file)
  local n = { 0, 0, 0, 0 }
  for _, diagnostic in ipairs(diagnostics(file)) do
    local s = severity(diagnostic)
    n[s] = n[s] + 1
  end
  return n
end

-- After the file name, focused window only
table.insert(modal.left, function(win)
  if win ~= vis.win then
    return
  end
  local diagnostic, others = at_line(win.file, win.selection.line)
  if not diagnostic then
    return
  end
  local s = severity(diagnostic)
  local message = tostring(diagnostic.message):gsub("%s*\n%s*", " ")
  local text = " " .. NAMES[s] .. ": " .. message .. (others > 0 and " (+" .. others .. ")" or "") .. " "
  return { { text, M.styles.message[s] } }
end)

-- Before line:col: E1 W2, plain without focus
table.insert(modal.right, function(win)
  local focused = win == vis.win
  local gap = focused and M.styles.gap or nil
  local n = counts(win.file)
  local parts = {}
  for s = 1, 4 do
    if n[s] > 0 then
      parts[#parts + 1] = { " ", gap }
      parts[#parts + 1] = { LETTERS[s] .. n[s], focused and M.styles.count[s] or nil }
    end
  end
  if #parts == 0 then
    return
  end
  parts[#parts + 1] = { " ", gap }
  parts[#parts + 1] = { " " } -- in the status line's color
  return parts
end)

return M

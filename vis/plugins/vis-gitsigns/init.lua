-- vis-gitsigns: tints what changed since the git index: added lines, changed
-- words, cut text, and the number of the line below removed lines
local style = require("plugins/style-compat")

local M = {}

M.styles = {
  add = "back:green", -- the text of an added line
  change = "back:blue", -- the changed text in a changed line
  cut = "back:red", -- where text was removed from a changed line
  removed = "back:red", -- the number of the line below removed lines
}
M.max_size = 1024 * 1024 -- bigger files get no signs
M.max_edits = 400 -- a diff that needs more edits is shown as one change

-- One id, redefined per kind: applying a style copies it into the cells
local STYLE = style.id(62)

-- By path: base (the index's lines) and the last diff's content, lines,
-- offsets, marks (by line: add, or change and cut columns) and removed
local state = {}

-- The lines of a text and the byte offset each one starts at
local function split(text)
  local lines, offsets = {}, {}
  local pos = 1
  while true do
    offsets[#offsets + 1] = pos - 1
    local newline = text:find("\n", pos, true)
    if not newline then
      lines[#lines + 1] = text:sub(pos)
      return lines, offsets
    end
    lines[#lines + 1] = text:sub(pos, newline - 1)
    pos = newline + 1
  end
end

-- Myers' diff: the deleted indices of a and inserted ones of b, nil past limit edits
local function myers(a, b, limit)
  local n, m = #a, #b
  local v, trace = { [1] = 0 }, {}
  for d = 0, math.min(n + m, limit) do
    local vd = {}
    for k = -d, d, 2 do
      local x
      if k == -d or (k ~= d and v[k - 1] < v[k + 1]) then
        x = v[k + 1] -- down: insert from b
      else
        x = v[k - 1] + 1 -- right: delete from a
      end
      local y = x - k
      while x < n and y < m and a[x + 1] == b[y + 1] do
        x, y = x + 1, y + 1
      end
      vd[k] = x
      if x >= n and y >= m then
        trace[d] = vd
        local deleted, inserted = {}, {}
        for back = d, 1, -1 do
          local prev, kk = trace[back - 1], x - y
          local down = kk == -back or (kk ~= back and prev[kk - 1] < prev[kk + 1])
          local pk = down and kk + 1 or kk - 1
          local px = prev[pk]
          local py = px - pk
          if down then
            inserted[py + 1] = true
          else
            deleted[px + 1] = true
          end
          x, y = px, py
        end
        return deleted, inserted
      end
    end
    trace[d] = vd
    v = vd
  end
end

-- Calls hunk(first_b, last_b, first_a, last_a) for each run of edits, in order
local function hunks(n, m, deleted, inserted, hunk)
  local i, j = 1, 1
  while i <= n or j <= m do
    if i <= n and j <= m and not deleted[i] and not inserted[j] then
      i, j = i + 1, j + 1
    else
      local first_i, first_j = i, j
      while (i <= n and deleted[i]) or (j <= m and inserted[j]) do
        if i <= n and deleted[i] then
          i = i + 1
        end
        if j <= m and inserted[j] then
          j = j + 1
        end
      end
      if i == first_i and j == first_j then
        return -- the lists ended unevenly: not a diff of them
      end
      hunk(first_j, j - 1, first_i, i - 1)
    end
  end
end

-- Tokens for the word diff: words, runs of spaces, single characters
local function tokens(line)
  local list, starts = {}, {}
  local pos = 1
  while pos <= #line do
    local s, e = line:find("^[%w_]+", pos)
    if not s then
      s, e = line:find("^%s+", pos)
    end
    if not s then
      s, e = line:find("^[\192-\255][\128-\191]*", pos) -- one UTF-8 character
    end
    if not s then
      s, e = pos, pos
    end
    list[#list + 1] = line:sub(s, e)
    starts[#starts + 1] = s
    pos = e + 1
  end
  return list, starts
end

-- A line's changes: column ranges of new text, and columns where text was only removed
local function word_diff(old, new)
  local a = tokens(old)
  local b, starts = tokens(new)
  local deleted, inserted = myers(a, b, M.max_edits)
  if not deleted then
    return { { 1, #new } }, {}
  end
  local changes, cuts = {}, {}
  hunks(#a, #b, deleted, inserted, function(first, last, first_old, last_old)
    local col = starts[first] or #new + 1
    local prev = changes[#changes]
    if last >= first then
      local stop = starts[last + 1] and starts[last + 1] - 1 or #new
      if prev and new:sub(prev[2] + 1, col - 1):match("^%s*$") then
        prev[2] = stop -- only spaces between: one span
      else
        changes[#changes + 1] = { col, stop }
      end
    elseif last_old >= first_old then
      cuts[#cuts + 1] = { col, col }
    end
  end)
  return changes, cuts
end

-- Diffs content against the base into st's marks
local function compute(st, content)
  local lines, offsets = split(content)
  local base, n, m = st.base, #st.base, #lines
  local pre, suf = 0, 0 -- the common lines at the start and the end
  while pre < n and pre < m and base[pre + 1] == lines[pre + 1] do
    pre = pre + 1
  end
  while suf < n - pre and suf < m - pre and base[n - suf] == lines[m - suf] do
    suf = suf + 1
  end
  local a, b = {}, {}
  for i = pre + 1, n - suf do
    a[#a + 1] = base[i]
  end
  for j = pre + 1, m - suf do
    b[#b + 1] = lines[j]
  end

  local deleted, inserted = myers(a, b, M.max_edits)
  if not deleted then -- too different: one change for all of it
    deleted, inserted = {}, {}
    for i = 1, #a do
      deleted[i] = true
    end
    for j = 1, #b do
      inserted[j] = true
    end
  end

  -- a text ending in a newline splits into an empty last line vis doesn't show
  local shown = (m > 1 and lines[m] == "") and m - 1 or m
  local marks, removed = {}, {}
  hunks(#a, #b, deleted, inserted, function(first, last, first_old, last_old)
    for j = first, last do
      local i = first_old + j - first
      if i <= last_old then
        local changes, cuts = word_diff(a[i], b[j])
        marks[pre + j] = { change = changes, cut = cuts }
      else
        marks[pre + j] = { add = true }
      end
    end
    if last_old - first_old > last - first then -- more lines went than came
      removed[math.min(pre + last + 1, shown)] = true
    end
  end)
  st.content, st.lines, st.offsets, st.marks, st.removed = content, lines, offsets, marks, removed
end

local function quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- The file's version in the git index, if any
local function load_base(file)
  local path = file and file.path
  if not path then
    return
  end
  local dir, name = path:match("^(.*)/([^/]+)$")
  if not dir then
    dir, name = ".", path
  end
  local git = io.popen(
    "git -C " .. quote(dir == "" and "/" or dir) .. " show " .. quote(":./" .. name) .. " 2>/dev/null </dev/null"
  )
  local text = git:read("a")
  local base = git:close() and split(text) or nil
  state[path] = { base = base }
end

-- A file's signs, diffed again when it changed
local function signs(file)
  local st = file and file.path and state[file.path]
  if not st or not st.base or file.size > M.max_size then
    return nil
  end
  local content = file:content(0, file.size)
  if content ~= st.content then
    compute(st, content)
  end
  return st
end

vis.events.subscribe(vis.events.FILE_OPEN, load_base)
vis.events.subscribe(vis.events.FILE_SAVE_POST, load_base)
vis.events.subscribe(vis.events.FILE_CLOSE, function(file)
  if file.path then
    state[file.path] = nil
  end
end)

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
  local st = signs(win.file)
  if not st then
    return
  end
  local lines = win.viewport.lines
  local function paint(kind, spans)
    style.define(win, STYLE, M.styles[kind])
    for line = lines.start, lines.finish do
      local mark = st.marks[line]
      for _, span in ipairs(mark and spans(mark, st.lines[line]) or {}) do
        win:style(STYLE, st.offsets[line] + span[1] - 1, st.offsets[line] + span[2] - 1)
      end
    end
  end
  paint("add", function(mark, text)
    if mark.add then
      local first = text:find("%S")
      return { first and { first, #text } or { #text + 1, #text + 1 } } -- a blank line: its end
    end
  end)
  paint("change", function(mark)
    return mark.change
  end)
  paint("cut", function(mark)
    return mark.cut
  end)
end)

-- A line's width in cells, to follow wrapped lines
local function width(line, tabwidth)
  if not line:find("\t", 1, true) then
    return utf8.len(line) or #line
  end
  local col = 0
  for char in line:gmatch("[%z\1-\127\192-\255][\128-\191]*") do
    col = char == "\t" and col + tabwidth - col % tabwidth or col + 1
  end
  return col
end

-- The number below removed lines: vis draws numbers after WIN_HIGHLIGHT, so this styles cells
vis.events.subscribe(vis.events.UI_DRAW, function()
  for win in vis:windows() do
    local st = win.file and win.file.path and state[win.file.path]
    local viewport = win.viewport
    local sidebar = win.width - viewport.width
    if st and st.removed and next(st.removed) and sidebar > 0 then
      style.define(win, STYLE, M.styles.removed)
      local tabwidth = win.options.tabwidth or 8
      local row = 0
      for line = viewport.lines.start, viewport.lines.finish do
        if row >= viewport.height then
          break
        end
        if st.removed[line] then
          for x = 0, sidebar - 1 do
            win:style_pos(STYLE, x, row)
          end
        end
        row = row + 1 + math.floor(width(st.lines[line] or "", tabwidth) / viewport.width)
      end
    end
  end
end)

return M

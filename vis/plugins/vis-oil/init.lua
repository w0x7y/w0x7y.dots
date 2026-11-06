-- vis-oil: edit a folder like a buffer, a port of oil.nvim. Copy this folder
-- next to your visrc.lua and map a key to open_parent, which opens the current
-- file's folder, or the parent folder in an oil buffer:
--
--   vis:map(vis.modes.NORMAL, "-", require("vis-oil").open_parent)
--
-- <Enter> opens the entry under the cursor.
-- One entry per line, folders end in /. Rename a line to rename the entry
-- (sub/name moves it into sub), delete a line to delete it, add one to create
-- a file, or a folder if it ends in /. :w lists the changes and asks first
local plan = require((...):gsub("[./]init$", "") .. "/plan")

local M = {
  styles = { dir = "fore:blue" },
}

local ui = vis.ui
local DIR = ui.style_push and ui:style_push() or 54 -- vis 0.9 has no free ids
local buffers = {} -- temp file -> { dir, names, entries }
local temp_of = {} -- folder -> its temp file

local function sh(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function join(dir, name)
  return name:sub(1, 1) == "/" and name or (dir == "/" and "" or dir) .. "/" .. name
end

-- The folder a path is in, and its name there
local function parent(path)
  local dir = path:match("^(.*)/[^/]*$")
  return (dir == nil or dir == "") and "/" or dir, path:match("[^/]*$")
end

local function exists(path)
  return os.rename(path, path) and true or false -- also folders and unreadable files
end

local function is_dir(path)
  local f = io.open(path .. "/")
  return f and f:close() and true or false
end

-- A folder's entries, folders first and ending in /
local function list(dir)
  local ls = io.popen("ls -1Ap -- " .. sh(dir) .. " 2>/dev/null </dev/null")
  local dirs, files = {}, {}
  for name in ls:lines() do
    table.insert(name:sub(-1) == "/" and dirs or files, name)
  end
  if not ls:close() then
    return nil
  end
  for _, name in ipairs(files) do
    dirs[#dirs + 1] = name
  end
  return dirs
end

local function shown(temp)
  for win in vis:windows() do
    if win.file.path == temp then
      return win
    end
  end
end

local function oil_of(win)
  return win and win.file and buffers[win.file.path]
end

-- The folder an oil window shows, ~/ for home, for a status line
function M.folder(win)
  local st = oil_of(win)
  if not st then
    return nil
  end
  local dir, home = st.dir, os.getenv("HOME")
  if home and (dir == home or dir:sub(1, #home + 1) == home .. "/") then
    dir = "~" .. dir:sub(#home + 1)
  end
  return (dir:gsub("/?$", "/"))
end

local enter

-- vis's o puts the new line before the current line's newline, which would
-- hand the entry's newline mark to the new line
local function open_below()
  local file, pos = vis.win.file, vis.win.selection.pos
  local newline = file:content(pos, file.size - pos):find("\n")
  pos = newline and pos + newline or file.size
  file:insert(pos, "\n")
  vis.win.selection.pos = pos
  vis.mode = vis.modes.INSERT
end

-- Marks each entry's first character and newline, so plan.lua can tell a
-- rename from a delete
local function setup(win, st, focus)
  win:set_syntax(nil)
  st.entries = {}
  local pos = 0
  for i, name in ipairs(st.names) do
    local file = win.file
    st.entries[i] = { name = name, first = file:mark_set(pos), newline = file:mark_set(pos + #name) }
    pos = pos + #name + 1
    if focus and (name == focus or name == focus .. "/") then
      win.selection:to(i, 1)
    end
  end
  win:map(vis.modes.NORMAL, "<Enter>", enter, "oil: open the entry under the cursor")
  win:map(vis.modes.NORMAL, "o", open_below, "oil: new entry below")
end

-- Shows a folder in this window, or a new one if this one has unsaved changes
function M.open(dir, focus)
  local names = list(dir)
  if not names then
    return vis:info("oil: can't read " .. dir)
  end
  local win = vis.win
  local temp = temp_of[dir]
  if not temp or (win.file.path ~= temp and shown(temp)) then
    temp = os.tmpname() -- one buffer per window
  end
  temp_of[dir] = temp
  local f = assert(io.open(temp, "w"))
  f:write(#names > 0 and table.concat(names, "\n") .. "\n" or "")
  f:close()

  local ok
  if win.file.path == temp then
    ok = vis:command("e!") -- new undo history: undo can't revert what :w did
  else
    ok = vis:command((win.file.modified and "open " or "e ") .. temp)
  end
  if ok and vis.win.file.path == temp then
    local st = { dir = dir, names = names }
    buffers[temp] = st
    setup(vis.win, st, focus)
  end
end

function enter()
  local win = vis.win
  local st = oil_of(win)
  if not st then
    return
  end
  local name = (win.file.lines[win.selection.line] or ""):match("^%s*(.-)%s*$")
  if name == "" then
    return
  end
  if win.file.modified then
    return vis:info("oil: :w to apply the changes first, or u to undo them")
  end
  local path = join(st.dir, name):gsub("(.)/+$", "%1")
  if is_dir(path) then
    M.open(path)
  else
    vis:command("e " .. path:gsub("[\\\t \"']", "\\%1"))
  end
end

function M.open_parent()
  local st = oil_of(vis.win)
  if st then
    if st.dir ~= "/" then
      M.open(parent(st.dir))
    end
    return
  end
  local path = vis.win.file.path
  if path then
    M.open(parent(path))
  else
    M.open(os.getenv("PWD") or "/")
  end
end

local function describe(op)
  if op[1] == "rename" then
    return "rename " .. op[2] .. " → " .. op[3]
  end
  return op[1] .. " " .. op[2] .. (op[1] == "delete" and op[2]:sub(-1) == "/" and " and everything in it" or "")
end

local function ask(lines)
  local prompt = "oil: " .. table.concat(lines, ", ") .. "?"
  local status, out = vis:pipe("printf 'no\\nyes\\n' | vis-menu -b -p " .. sh(prompt), false)
  vis:redraw()
  return status == 0 and out and out:match("^yes") ~= nil
end

-- Checks every target first; an error stops the rest
local function apply(dir, ops)
  for _, op in ipairs(ops) do
    local target = op[1] == "rename" and op[3] or op[1] == "create" and op[2]
    if target and exists(join(dir, target:gsub("/+$", ""))) then
      return target .. " already exists"
    end
  end
  for _, op in ipairs(ops) do
    local kind, a, b = op[1], join(dir, op[2]):gsub("/+$", ""), op[3] and join(dir, op[3]):gsub("/+$", "")
    local ok, err
    if kind == "rename" then
      os.execute("mkdir -p -- " .. sh(parent(b)))
      ok, err = os.rename(a, b)
    elseif kind == "create" then
      if op[2]:sub(-1) == "/" then
        ok = os.execute("mkdir -p -- " .. sh(a))
      else
        os.execute("mkdir -p -- " .. sh(parent(a)))
        local f
        f, err = io.open(a, "a") -- never empties a file that appeared meanwhile
        ok = f and f:close()
      end
    elseif is_dir(a) then
      ok = os.execute("rm -rf -- " .. sh(a))
    else
      ok, err = os.remove(a)
    end
    if not ok then
      return describe(op) .. " failed" .. (err and ": " .. err or "")
    end
  end
end

-- Reloading inside the save event would free the file while vis still uses
-- it, so the refresh waits for a process to exit
local refresh = {}

vis.events.subscribe(vis.events.FILE_SAVE_POST, function(file)
  local st = buffers[file.path]
  if not st then
    return
  end
  local entries = {}
  for i, entry in ipairs(st.entries) do
    entries[i] = { name = entry.name, first = file:mark_get(entry.first), newline = file:mark_get(entry.newline) }
  end
  local ops, err = plan(file:content(0, file.size), entries)
  if not ops then
    file.modified = true
    return vis:info("oil: " .. err)
  end
  if #ops > 0 then
    local lines = {}
    for i, op in ipairs(ops) do
      lines[i] = describe(op)
    end
    if not ask(lines) then
      file.modified = true -- the edits stay, unsaved
      return
    end
    err = apply(st.dir, ops)
  end
  if err then
    vis:info("oil: " .. err)
  end
  refresh[file.path] = st.dir
  local fd = vis:communicate("vis-oil", "true")
  if fd then
    fd:close()
  end
end)

vis.events.subscribe(vis.events.PROCESS_RESPONSE, function(name, event)
  if name ~= "vis-oil" or (event ~= "EXIT" and event ~= "SIGNAL") then -- closing its input may kill it
    return
  end
  local current = vis.win
  for win in vis:windows() do
    local dir = refresh[win.file.path]
    if dir then
      vis.win = win
      local line = win.selection.line
      M.open(dir)
      vis.win.selection:to(math.max(1, math.min(line, #vis.win.file.lines)), 1)
    end
  end
  refresh = {}
  vis.win = current
end)

vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
  if not oil_of(win) then
    return
  end
  if ui.style_define then
    ui:style_define(DIR, M.styles.dir)
  else
    win:style_define(DIR, M.styles.dir)
  end
  local v = win.viewport.bytes
  local text = win.file:content(v.start, v.finish - v.start)
  for start, line, finish in text:gmatch("()([^\n]*)()") do
    if line:match("/%s*$") then
      win:style(DIR, v.start + start - 1, v.start + finish - 2)
    end
  end
end)

vis.events.subscribe(vis.events.QUIT, function()
  for temp in pairs(buffers) do
    os.remove(temp)
  end
end)

return M

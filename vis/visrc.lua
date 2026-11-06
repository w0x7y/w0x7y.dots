require("vis")

-- Options

vis.events.subscribe(vis.events.INIT, function()
  -- the sway theme script writes the variant
  local f = io.open(os.getenv("HOME") .. "/.local/state/rime/variant")
  local theme = f and f:read("l") == "rime-frost" and "rime-frost" or "rime"
  if f then
    f:close()
  end
  vis:command("set theme " .. theme)
  vis:command("set ignorecase on")
  vis:command("set shell /bin/sh") -- the commands here are POSIX sh, not fish
end)

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
  vis:command("set relativenumbers on")
  vis:command("set tabwidth 2")
  vis:command("set expandtab " .. (win.syntax == "go" and "off" or "on")) -- gofmt indents with tabs
  vis:command("set autoindent on")
  vis:command("set colorcolumn 80")
end)

vis.ftdetect.filetypes.revo = { ext = { "%.rv$", "%.revo$" }, utility = { "^revo$" } }

-- Plugins

require("plugins/vis-modal") -- status line
require("plugins/vis-autoclose")
require("plugins/vis-colorizer")
require("plugins/vis-gitsigns")
require("plugins/vis-cursor")
require("plugins/vis-modal").name = require("plugins/vis-oil").folder -- oil's folder, not its temp file
require("config/lsp") -- before the keys: it unmaps lspc's <Space>e
require("config/diagnostics")
require("config/format")

-- Keys: leader is <Space>, LSP keys are in config/lsp.lua

local normal, visual = vis.modes.NORMAL, vis.modes.VISUAL

-- System clipboard. Not "+y, which hangs vis 0.9 with wl-copy
vis:map(visual, " y", ":>vis-clipboard --copy >/dev/null 2>&1<Enter><Escape>", "Copy to the clipboard")
vis:map(normal, " p", '"+p', "Paste the clipboard")

vis:map(visual, "<Tab>", "<vis-operator-shift-right>gv", "Indent selection")
vis:map(visual, "<S-Tab>", "<vis-operator-shift-left>gv", "Dedent selection")

for _, mode in ipairs({ normal, visual, vis.modes.OPERATOR_PENDING }) do
  vis:map(mode, "S", "<vis-search-forward>", "Search forward")
end

local fd = "fd --type f -E node_modules -E bin -E obj </dev/null"

-- Opens the first path cmd prints, in a new window if this one is modified
local function open_from(cmd)
  local status, out = vis:pipe(cmd, false)
  vis:redraw()
  local path = status == 0 and out and out:match("[^\n]+")
  if not path then
    return false
  end
  vis:command((vis.win.file.modified and "open " or "e ") .. path:gsub("[\\\t \"']", "\\%1"))
  return true
end

local function find()
  open_from(fd .. " | vis-menu -b -i -p find")
end

vis:map(normal, " e", function()
  open_from("vis-open -p explore -- . </dev/null")
end, "File explorer")

vis:map(normal, " ff", find, "Find a file")

vis:command_register("find", function(argv)
  local query = table.concat(argv, " ")
  if query == "" then
    find()
  elseif not open_from(fd .. " | fzf --filter='" .. query:gsub("'", "'\\''") .. "' | head -n 1") then
    vis:info("No file matches " .. query)
  end
end, "Open a file: a menu, or the best match for the argument")

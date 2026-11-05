-- No picker plugin: fuzzy : commands, :find via fd, :grep via rg, netrw sidebar

-- Folders that :find and :grep skip, on top of gitignored files
local ignore = { "node_modules", "bin", "obj" }

-- : commands get a fuzzy menu as you type; nothing is preselected, so <CR> runs what you typed
vim.opt.wildmode = "noselect:lastused,full"
vim.opt.wildoptions = "pum,fuzzy"
vim.api.nvim_create_autocmd("CmdlineChanged", {
  pattern = ":",
  callback = function()
    vim.fn.wildtrigger()
  end,
})

-- :find fuzzy-matches every file in the project (fd skips gitignored files)
local fd = { "fd", "--type", "f" }
for _, dir in ipairs(ignore) do
  vim.list_extend(fd, { "-E", dir })
end
local files
vim.api.nvim_create_autocmd("CmdlineEnter", {
  callback = function()
    files = nil -- list files once per command line, not on every keystroke
  end,
})
-- Menus list the best match last, right above the command line, like fzf.
-- shortcut: only the top matches are listed so the best can't scroll out of view; type more to narrow
local function bottom_up(matches)
  return vim.iter(vim.list_slice(matches, 1, 15)):rev():totable()
end
function _G.Find(arg, cmdcomplete)
  files = files or vim.fn.systemlist(fd)
  local matches = arg == "" and files or vim.fn.matchfuzzy(files, arg)
  return cmdcomplete and bottom_up(matches) or matches -- <CR> without picking opens the best match
end
vim.opt.findfunc = "v:lua.Find"

-- :B is :buffer with a bottom-up menu, last used first, without the current buffer
local function buffer_matches(arg)
  local bufs = vim.tbl_filter(function(b)
    return b.bufnr ~= vim.fn.bufnr()
  end, vim.fn.getbufinfo({ buflisted = 1 }))
  table.sort(bufs, function(x, y)
    return x.lastused > y.lastused
  end)
  local names = vim.tbl_map(function(b)
    return vim.fn.fnamemodify(b.name, ":~:.")
  end, bufs)
  return arg == "" and names or vim.fn.matchfuzzy(names, arg)
end
vim.api.nvim_create_user_command("B", function(o)
  vim.cmd.buffer(buffer_matches(o.args)[1] or o.args)
end, {
  nargs = 1,
  complete = function(arg)
    return bottom_up(buffer_matches(arg))
  end,
})

-- In those menus Tab moves up from the best match and Shift-Tab back down
local function bottom_up_menu()
  local cmd = vim.fn.fullcommand(vim.fn.getcmdline():match("^%a*"))
  return vim.fn.wildmenumode() == 1 and (cmd == "find" or cmd == "B")
end
vim.opt.wildcharm = 9 -- <Tab> returned by the maps below still completes
vim.keymap.set("c", "<Tab>", function()
  return bottom_up_menu() and "<C-p>" or "<Tab>"
end, { expr = true })
vim.keymap.set("c", "<S-Tab>", function()
  return bottom_up_menu() and "<C-n>" or "<S-Tab>"
end, { expr = true })

-- :grep fills the quickfix list and opens it, one line per match up to 10 lines
vim.opt.grepprg = "rg --line-number --column --no-heading --smart-case --glob=!" .. table.concat(ignore, " --glob=!") -- one entry per matching line
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  pattern = "[^l]*",
  callback = function()
    vim.cmd.cwindow()
    local win = vim.fn.getqflist({ winid = 0 }).winid
    if win ~= 0 then -- cwindow leaves an already open window at its old height
      vim.api.nvim_win_set_height(win, math.min(#vim.fn.getqflist(), 10))
    end
  end,
})

-- Keys
vim.keymap.set("n", "<leader>ff", ":find ", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", ":silent grep ", { desc = "Grep" }) -- silent: don't print rg's raw output over the editor
vim.keymap.set("n", "<leader>fb", ":B ", { desc = "Find buffers" })
vim.keymap.set("n", "<leader>fk", "<cmd>map<CR>", { desc = "List keymaps" })
vim.keymap.set("n", "<leader>fd", vim.diagnostic.setqflist, { desc = "List diagnostics" })
vim.keymap.set("n", "<leader>e", "<cmd>Lexplore<CR>", { desc = "Toggle file explorer sidebar (netrw)" })

-- netrw as a tree sidebar
vim.g.netrw_banner = 0 -- no help header; I shows it again
vim.g.netrw_liststyle = 3 -- tree view
vim.g.netrw_winsize = -22 -- negative: sidebar width in columns, not percent
vim.g.Netrw_funcref = function() -- runs after netrw opens a file
  if vim.t.netrw_lexbufnr then
    vim.cmd("Lexplore") -- picked from the sidebar: close it
  end
end

-- netrw keys: a adds a file (or a folder when the name ends in /), d deletes, r renames.
-- Not netrw's own D/R: in tree view they act on the top folder, so d on sub/x.txt deleted ./x.txt
local netrw = vim.fn["netrw#Call"]

-- Full path of the entry under the cursor; folders end in /. nil on ../
local function netrw_path()
  local word = netrw("NetrwGetWord"):gsub("@$", "") -- @ marks a symlink
  if word == "../" or word == "./" then
    return nil
  end
  if not vim.w.netrw_treetop then
    return vim.fs.joinpath(vim.b.netrw_curdir, word)
  end
  local dir = netrw("NetrwTreePath", vim.w.netrw_treetop) -- the folder line itself, or the file's folder
  return vim.endswith(word, "/") and dir or dir .. word
end

local function netrw_refresh()
  vim.cmd([[execute "normal \<Plug>NetrwRefresh"]])
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    local opts = { buffer = ev.buf, nowait = true }
    vim.keymap.set({ "n", "x" }, "D", "<Nop>", opts) -- netrw's own delete and rename, replaced by d and r
    vim.keymap.set({ "n", "x" }, "R", "<Nop>", opts)
    vim.keymap.set("n", "a", function()
      local path = netrw_path() or vim.b.netrw_curdir .. "/"
      local dir = vim.endswith(path, "/") and path or vim.fs.dirname(path)
      local name = vim.fn.input("New file (end with / for a folder): ")
      if name == "" then
        return
      end
      path = vim.fs.joinpath(dir, name)
      if vim.uv.fs_stat(path) then
        return vim.notify(name .. " already exists", vim.log.levels.WARN)
      end
      if vim.endswith(name, "/") then
        vim.fn.mkdir(path, "p")
      else
        vim.fn.mkdir(vim.fs.dirname(path), "p") -- a/b.txt also creates a/
        vim.fn.writefile({}, path)
      end
      netrw_refresh()
    end, opts)

    vim.keymap.set("n", "d", function()
      local path = netrw_path()
      if not path then
        return
      end
      local what = vim.endswith(path, "/") and "folder and everything in it" or "file"
      path = path:gsub("/$", "")
      if vim.fn.confirm(("Delete %s %s?"):format(what, path), "&Yes\n&No", 2) == 1 then
        vim.fs.rm(path, { recursive = true })
        netrw_refresh()
      end
    end, opts)

    vim.keymap.set("n", "r", function()
      local old = netrw_path()
      if not old then
        return
      end
      old = old:gsub("/$", "")
      local new = vim.fn.input("Rename to: ", old, "file")
      if new == "" or new == old then
        return
      end
      if vim.uv.fs_stat(new) then
        return vim.notify(new .. " already exists", vim.log.levels.WARN)
      end
      local ok, err = vim.uv.fs_rename(old, new)
      if not ok then
        return vim.notify(err, vim.log.levels.ERROR)
      end
      netrw_refresh()
    end, opts)
  end,
})

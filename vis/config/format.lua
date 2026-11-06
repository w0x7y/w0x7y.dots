-- Format on save, all at 2 spaces

local function sh(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Each returns a command that formats stdin to stdout; the path finds the formatter's config
local function stylua(path)
  return "stylua --indent-type Spaces --indent-width 2 --search-parent-directories --stdin-filepath "
    .. sh(path)
    .. " -"
end

local function clang_format(path)
  return "clang-format "
    .. sh("--style={BasedOnStyle: LLVM, IndentWidth: 2, TabWidth: 2, UseTab: Never}")
    .. " --assume-filename="
    .. sh(path)
end

local function ruff(path)
  return "ruff format --force-exclude --stdin-filename " .. sh(path) .. " --config indent-width=2 -"
end

local function rustfmt()
  return "rustfmt --emit=stdout --edition=2021 --config tab_spaces=2"
end

local function csharpier()
  return "csharpier format --write-stdout --config-path " .. sh(os.getenv("HOME") .. "/.config/vis/csharpier.json")
end

local function prettier(path)
  return "prettier --tab-width 2 --stdin-filepath " .. sh(path)
end

-- goimports also fixes imports; gofmt without it
local function goimports(path)
  return "command -v goimports >/dev/null && exec goimports -srcdir " .. sh(path) .. " || exec gofmt"
end

local function zig_fmt()
  return "zig fmt --stdin"
end

local function revofmt(path)
  return "revofmt --indent-width 2 --line-width 80 --stdin-filepath " .. sh(path)
end

local by_ext = {
  lua = stylua,
  c = clang_format,
  h = clang_format,
  cpp = clang_format,
  cc = clang_format,
  cxx = clang_format,
  hpp = clang_format,
  hh = clang_format,
  py = ruff,
  pyi = ruff,
  rs = rustfmt,
  cs = csharpier,
  go = goimports,
  zig = zig_fmt,
  zon = zig_fmt,
  rv = revofmt,
  revo = revofmt,
  html = prettier,
  css = prettier,
  scss = prettier,
  js = prettier,
  mjs = prettier,
  cjs = prettier,
  jsx = prettier,
  ts = prettier,
  tsx = prettier,
  json = prettier,
  jsonc = prettier,
  md = prettier,
  markdown = prettier,
  yaml = prettier,
  yml = prettier,
}

local function formatter_for(path, syntax)
  local ext = path:match("%.([^./]+)$")
  if ext then
    return by_ext[ext:lower()]
  end
  if syntax == "revo" then -- a script with a revo shebang
    return revofmt
  end
end

-- Replaces only what changed, so the cursor, marks and undo stay put
local function apply(file, win, new)
  local old = file:content(0, file.size)
  if new == old then
    return
  end
  local max = math.min(#old, #new)
  local p = 0
  while p < max and old:byte(p + 1) == new:byte(p + 1) do
    p = p + 1
  end
  local s = 0
  while s < max - p and old:byte(#old - s) == new:byte(#new - s) do
    s = s + 1
  end
  local line, col = win and win.selection.line, win and win.selection.col
  file:delete(p, #old - s - p)
  file:insert(p, new:sub(p + 1, #new - s))
  if win then
    win.selection:to(line, col)
  end
end

local function format(formatter, file, path, win)
  local status, out, err = vis:pipe(file, { start = 0, finish = file.size }, formatter(path))
  if status ~= 0 or not out then
    return vis:info((err and err:match("[^\n]+")) or ("formatter exited with " .. tostring(status)))
  end
  apply(file, win, out)
end

-- Caught: an error here would cancel the save
vis.events.subscribe(vis.events.FILE_SAVE_PRE, function(file, path)
  path = path or file.path
  if not path or file.size == 0 then
    return
  end
  local win -- showing the file, preferably the current one
  for w in vis:windows() do
    if w.file == file then
      win = w
      if w == vis.win then
        break
      end
    end
  end
  local formatter = formatter_for(path, win and win.syntax)
  if formatter then
    local ok, err = pcall(format, formatter, file, path, win)
    if not ok then
      vis:info("format on save: " .. tostring(err))
    end
  end
end)

-- Language servers and LSP keys (vis-lspc)
local lspc = require("plugins/vis-lspc")

-- Servers by vis syntax name, run from $PATH
local servers = {
  {
    syntaxes = { "ansi_c", "cpp" },
    name = "clangd",
    cmd = "clangd",
    roots = { ".clangd", ".clang-tidy", ".clang-format", "compile_commands.json", "compile_flags.txt", "configure.ac" },
  },
  {
    syntaxes = { "lua" },
    name = "lua-language-server",
    cmd = "lua-language-server",
    roots = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
    settings = { Lua = { diagnostics = { globals = { "vis" } }, telemetry = { enable = false } } },
  },
  {
    syntaxes = { "python" },
    name = "pyright",
    cmd = "pyright-langserver --stdio",
    roots = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", "pyrightconfig.json" },
    settings = {
      python = {
        analysis = { autoSearchPaths = true, useLibraryCodeForTypes = true, diagnosticMode = "openFilesOnly" },
      },
    },
  },
  {
    syntaxes = { "rust" },
    name = "rust-analyzer",
    cmd = "rust-analyzer",
    roots = { "Cargo.toml" },
  },
  {
    syntaxes = { "go" },
    name = "gopls",
    cmd = "gopls",
    roots = { "go.work", "go.mod" },
  },
  {
    syntaxes = { "zig" },
    name = "zls",
    cmd = "zls",
    roots = { "zls.json", "build.zig" },
  },
  {
    syntaxes = { "javascript", "typescript" }, -- .jsx and .tsx too
    name = "ts_ls",
    cmd = "typescript-language-server --stdio",
    roots = { "tsconfig.json", "jsconfig.json", "package.json" },
  },
  {
    syntaxes = { "html" },
    name = "html",
    cmd = "vscode-html-language-server --stdio",
    roots = { "package.json" },
    init_options = {
      embeddedLanguages = { css = true, javascript = true },
      configurationSection = { "html", "css", "javascript" },
    },
  },
  {
    syntaxes = { "css", "sass", "less" }, -- sass is vis's .scss
    name = "cssls",
    cmd = "vscode-css-language-server --stdio",
    roots = { "package.json" },
    settings = { css = { validate = true }, scss = { validate = true }, less = { validate = true } },
  },
  {
    syntaxes = { "json" },
    name = "jsonls",
    cmd = "vscode-json-language-server --stdio",
  },
  {
    syntaxes = { "csharp" },
    name = "omnisharp",
    cmd = "OmniSharp -z DotNet:enablePackageRestore=false --encoding utf-8 --languageserver",
    roots = { "*.sln", "*.csproj", "omnisharp.json", "function.json" },
  },
  {
    syntaxes = { "revo" },
    name = "revo",
    cmd = "revo lsp",
    roots = { "lib.json", "exe.json" },
  },
}

for _, server in ipairs(servers) do
  for _, syntax in ipairs(server.syntaxes) do
    lspc.ls_map[syntax] = server
  end
end

lspc.universal_root_globs = { ".git" }
lspc.autoconfirm_edits = true -- grn renames without asking
lspc.highlight_diagnostics = "range" -- color the problem, not the line number
-- -b: menus on the bottom line, not over the code
lspc.menu_cmd = "vis-menu -b"
lspc.confirm_cmd = "vis-menu -b"
lspc.navwin_layout = "vl" -- the default "vr" draws symbols over the buffer

-- Keep lspc's gd, <C-t> and insert <C-Space>; the status line replaces K
local normal = vis.modes.NORMAL

for _, key in ipairs({ "K", "<F2>", "<F3>", "<C-]>", "gD", "gi", "gr", " D", " e", " n", " N", " o", "<C-K>", "<C- >" }) do
  vis:unmap(normal, key)
end

-- Rename, the name under the cursor already typed
vis:map(normal, "grn", function()
  local file = vis.win.file
  local range = file:text_object_word(vis.win.selection.pos)
  local word = range and file:content(range) or ""
  vis:feedkeys(":lspc-rename " .. (word:match("^[%w_]+$") or ""))
end, "lspc: rename")

vis:map(normal, "]d", ":lspc-next-diagnostic<Enter>", "lspc: next diagnostic")
vis:map(normal, "[d", ":lspc-prev-diagnostic<Enter>", "lspc: previous diagnostic")

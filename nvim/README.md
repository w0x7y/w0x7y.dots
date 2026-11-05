# nvim, w0x7y special

my neovim config. one file per feature, [rime](https://github.com/w0x7y/rime) colors and [revo](https://github.com/if-not-nil/revo) support

<p align="center">
<img width="49%" alt="editing revo in rime, with inlay hints and a diagnostic" src="assets/1.png" />
<img width="49%" alt="grep results in the quickfix list beside the netrw sidebar" src="assets/2.png" />
</p>

<p align="center">
<a href="#install">install</a> |
<a href="#keys">keys</a> |
<a href="#whats-in-it">what's in it</a> |
<a href="#revo">revo</a> |
<a href="#layout">layout</a>
</p>

### install

needs neovim `0.12`+, git and a nerd font

```sh
git clone https://github.com/w0x7y/w0x7y.dots
cp -r w0x7y.dots/nvim ~/.config/
nvim
```

lazy.nvim installs itself and every plugin on first start\
mason then installs the language servers

<details>
<summary>~ other programs it calls</summary>

<br>

| program                                                              | for                                               |
| -------------------------------------------------------------------- | ------------------------------------------------- |
| `fd`                                                                 | `<leader>ff`                                      |
| `rg`                                                                 | `<leader>fg`                                      |
| `tree-sitter` cli and a c compiler                                   | building parsers                                  |
| `revo`                                                               | the revo lsp, from `$PATH` or `~/.local/bin/revo` |
| a python venv in `~/.local/share/better-sql-venv`                    | better-sql.nvim                                   |
| kitty, wezterm or ghostty                                            | showing images                                    |
| `magick`                                                             | images that aren't png                            |
| `stylua`, `ruff`, `prettier`, `clang-format`, `rustfmt`, `csharpier`, `goimports`, `gofumpt`| formatting on save                                |

on arch: `pacman -S stylua ruff prettier clang gofumpt go-tools`, `rustfmt` comes with rust, and `dotnet tool install -g csharpier` with `~/.dotnet/tools` on your `PATH`

</details>

### keys

leader is `<space>`

| key          | does                                     |
| ------------ | ---------------------------------------- |
| `<leader>ff` | find files, `:find` with a fuzzy menu    |
| `<leader>fg` | grep the project into the quickfix list  |
| `<leader>fb` | buffers, `:buffer` with a fuzzy menu     |
| `<leader>fk` | list every keymap                        |
| `<leader>fd` | every diagnostic, in the quickfix list   |
| `<leader>e`  | toggle the file explorer sidebar (netrw) |
| `<leader>jf` | format the file or selection             |
| `S`          | flash jump                               |
| `gd`         | go to definition                         |

the other lsp keys are neovim's own: `grr` references, `grn` rename, `gra` code action, `gri` implementation, `gO` symbols, `K` hover

in completion, `<Tab>` and `<S-Tab>` move through items and snippet fields\
`<CR>` only confirms an item you picked, `<C-space>` shows its docs\
snippets stay out of the menu. type `@` before a word, like `@for`, to list only snippets. the `@` goes away when one expands

### what's in it

~ [rime](https://github.com/w0x7y/rime) colorscheme, switch variants in `lua/plugins/colorscheme.lua`\
~ snacks.nvim for images, indent guides and highlighting other uses of the word under the cursor\
~ image files open as the picture, and markdown images show inline at up to 40x15 cells\
~ no picker plugin. `:` commands get a fuzzy menu as you type, and `:find` lists files with `fd`\
~ no file tree plugin. `<leader>e` opens netrw as a 22 column tree on the left, and picking a file closes it\
~ `<leader>fg` runs `rg` and opens the matches in a quickfix window that fits them, up to 10 lines. `]q` and `[q` step through\
~ git and diagnostic signs go before the line number and take their own column\
~ blink.cmp with its own snippet engine and friendly-snippets\
~ mason installs clangd, omnisharp, lua_ls, pyright, rust_analyzer, gopls, html, cssls, ts_ls, eslint and jsonls\
~ conform formats on save with stylua, csharpier, clang-format, ruff, rustfmt, goimports + gofumpt and prettier, all at 2 spaces except go, which gofmt keeps on tabs. csharpier gets its indent from `csharpier.json`\
~ `<Tab>` and `>>` indent 2 spaces in every filetype. python, rust, markdown and go don't switch to their own style\
~ diagnostics show in full under the cursor's line and nowhere else\
~ neovim 0.12's new message ui, so no "press ENTER" prompts\
~ the command line only shows while you type. messages show bottom right on the editor background for 4 seconds, `g<` brings the last one back\
~ treesitter indents and folds too. files open with every fold open\
~ `:Undotree` browses the undo history, which survives closing the file\
~ lualine shows `recording @q` while a macro records\
~ treesitter, lualine, gitsigns, autopairs, ts-autotag, render-markdown, lazydev\
~ [better-sql.nvim](https://github.com/w0x7y/better-sql.nvim) with a `supabase` connection read from `~/.pg_service.conf`

### revo

`lua/config/revo.lua` and `ftplugin/revo.lua` set up [revo](https://github.com/if-not-nil/revo) by hand

~ `.rv`, `.revo` and files with a revo shebang get the `revo` filetype\
~ `revo lsp` runs as the language server, with inlay hints on\
~ the parser builds from `~/.local/share/revo/tree-sitter-revo-current`\
~ [revofmt.nvim](https://github.com/w0x7y/revofmt.nvim) formats on save\
~ 43 snippets in `snippets/revo.json`, like `fn`, `match`, `test`, `class` and `cli`

> [!TIP]
> set `vim.g.revo_executable` or `vim.g.revo_grammar_path` before `require("config.revo")` in `init.lua` to use another binary or grammar

### layout

```text
init.lua                    leader, then loads lua/config/
csharpier.json              csharpier's 2 space indent
lua/config/options.lua      options, diagnostics, yank highlight
lua/config/finder.lua       fuzzy : menu, :find, :grep, netrw and their keys
lua/config/lsp.lua          gd on every lsp
lua/config/lazy.lua         lazy.nvim bootstrap
lua/config/revo.lua         revo filetype, lsp and parser
lua/plugins/colorscheme.lua rime
lua/plugins/treesitter.lua  treesitter and its parsers
lua/plugins/lsp.lua         mason, lspconfig, lazydev
lua/plugins/completion.lua  blink.cmp and the @ snippet trigger
lua/plugins/formatting.lua  conform and <leader>jf
lua/plugins/editor.lua      flash, autopairs, ts-autotag, gitsigns
lua/plugins/ui.lua          lualine, render-markdown
lua/plugins/snacks.lua      snacks: images, indent guides, words
lua/plugins/revo.lua        revofmt.nvim
lua/plugins/sql.lua         better-sql.nvim
ftplugin/revo.lua           revo comments and highlighting
snippets/                   revo snippets, loaded by blink.cmp
assets/                     readme screenshots and demo.rv, the file they show
```

_license: [mit](../LICENSE)_

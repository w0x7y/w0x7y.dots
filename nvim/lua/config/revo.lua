-- Revo's CLI bundles Revolt. Requires Neovim 0.11+ and nvim-treesitter main.
vim.filetype.add({
  extension = { rv = "revo", revo = "revo" },
  pattern = {
    [".*"] = {
      function(_, bufnr)
        local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
        if first:match("^#!.*%f[%w]revo%f[%W]") then
          return "revo"
        end
      end,
      { priority = -math.huge },
    },
  },
})

local executable = vim.g.revo_executable or vim.fn.exepath("revo")
if executable == "" then
  executable = vim.fn.expand("~/.local/bin/revo")
end
-- Completion capabilities come from blink.cmp, which sets them for every server.
vim.lsp.config("revo", {
  cmd = { executable, "lsp" },
  filetypes = { "revo" },
  root_markers = { "lib.json", "exe.json", ".git" },
})
vim.lsp.enable("revo")

-- The local checkout matches the public grammar revision in extension.toml.
local function register_parser()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if ok then
    parsers.revo = {
      install_info = {
        path = vim.g.revo_grammar_path or vim.fn.expand("~/.local/share/revo/tree-sitter-revo-current"),
        queries = "queries",
      },
    }
  end
end

local group = vim.api.nvim_create_augroup("Revo", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "TSUpdate",
  callback = register_parser,
})
register_parser()

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.name == "revo" and client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
    end
  end,
})

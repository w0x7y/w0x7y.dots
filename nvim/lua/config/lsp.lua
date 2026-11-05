-- Servers come from lua/plugins/lsp.lua; revo's from lua/config/revo.lua

-- gd for every LSP; the rest is built in: grn rename, gra code action, grr references, gri implementation, gO symbols, K hover
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf, desc = "Go to definition" })
  end,
})

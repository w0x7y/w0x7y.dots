vim.bo.commentstring = "# %s"
vim.bo.comments = ":#"
vim.bo.softtabstop = 2 -- shiftwidth, tabstop and expandtab come from lua/config/options.lua
-- LSP remains usable while the parser is being installed or rebuilt.
local ok, err = pcall(vim.treesitter.start, 0, "revo")
if not ok then
  vim.notify("Revo highlighting unavailable: " .. tostring(err), vim.log.levels.WARN)
end

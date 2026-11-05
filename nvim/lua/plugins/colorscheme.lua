return {
  "w0x7y/Rime",
  lazy = false,
  priority = 1000,
  config = function()
    require("rime").setup({})
    -- Variants: rime, rime-glacier, rime-aurora, rime-abyss
    vim.cmd.colorscheme("rime")
  end,
}

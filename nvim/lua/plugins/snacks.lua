return {
  -- Snacks.nvim
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      indent = { animate = { enabled = false } }, -- indent guides, drawn without animation
      quickfile = { enabled = true }, -- Instantly loads file text before heavy extensions run
      words = { enabled = true }, -- Highlights matching variables under cursor
      -- Show image files (and markdown images) through kitty's graphics protocol
      image = {
        enabled = true,
        doc = { max_width = 40, max_height = 15 }, -- markdown images, in cells
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)

      -- Leaving an image file hides its picture, and snacks never un-hides it, so it came back blank
      local Placement = require("snacks.image.placement")
      local update = Placement.update
      Placement.update = function(self)
        if
          self.hidden
          and vim.api.nvim_buf_is_valid(self.buf)
          and vim.bo[self.buf].filetype == "image"
          and #self:wins() > 0
        then
          self.hidden = false
        end
        return update(self)
      end
    end,
  },
}

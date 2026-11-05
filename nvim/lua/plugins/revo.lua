return {
  -- RevoFMT
  {
    "w0x7y/revofmt.nvim",
    main = "revofmt",
    lazy = false,
    opts = {
      indent_width = 2, -- 1 to 8 spaces
      line_width = 80, -- 20 to 240 columns; a soft target
      format_on_save = true,
    },
    build = function()
      local ok, err = require("revofmt").install({ async = false })
      if not ok then
        error(err)
      end
    end,
  },
}

return {
  -- Better status line(Lualine)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
          icons_enabled = true,
          globalstatus = true, -- one statusline across all splits
          section_separators = { left = "", right = "" },
          component_separators = "",
        },
        sections = {
          lualine_x = {
            -- showmode is off, so show macro recording here
            {
              function()
                return "recording @" .. vim.fn.reg_recording()
              end,
              cond = function()
                return vim.fn.reg_recording() ~= ""
              end,
              color = "WarningMsg",
            },
            "filetype",
          },
        },
      })
      vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
        callback = function()
          vim.schedule(require("lualine").refresh) -- the register is still set during RecordingLeave
        end,
      })
    end,
  },

  -- Render markdown
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {},
  },
}

return {
  -- Formatter
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local conform = require("conform")
      local format_opts = { lsp_format = "fallback", timeout_ms = 1000 }

      conform.setup({
        formatters_by_ft = {
          lua = { "stylua" },
          cs = { "csharpier" },
          c = { "clang-format" },
          cpp = { "clang-format" },
          python = { "ruff_format" },
          rust = { "rustfmt" },
          go = { "goimports", "gofumpt" }, -- gofmt style is fixed: tabs, not 2 spaces
          html = { "prettier" },
          css = { "prettier" },
          scss = { "prettier" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
          json = { "prettier" },
          jsonc = { "prettier" },
          markdown = { "prettier" },
          yaml = { "prettier" },
        },

        formatters = {
          ["clang-format"] = {
            prepend_args = { "--style={BasedOnStyle: LLVM, IndentWidth: 2, TabWidth: 2, UseTab: Never}" },
          },
          prettier = { prepend_args = { "--tab-width", "2" } },
          stylua = { prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" } },
          rustfmt = { prepend_args = { "--config", "tab_spaces=2" } },
          ruff_format = { append_args = { "--config", "indent-width=2" } },
          -- csharpier only reads indent size from a config file
          csharpier = { append_args = { "--config-path", vim.fn.stdpath("config") .. "/csharpier.json" } },
        },

        -- Format automatically on save
        format_on_save = format_opts,
      })

      -- Manual format: <leader>jf
      vim.keymap.set({ "n", "v" }, "<leader>jf", function()
        conform.format(format_opts)
      end, { desc = "Format file or range" })
    end,
  },
}

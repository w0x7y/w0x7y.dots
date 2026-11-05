return {
  -- Mason
  {
    "mason-org/mason.nvim",
    cmd = "Mason", -- otherwise loads with the LSP setup below
    opts = {},
  },

  -- Mason LSP config
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = true, -- loaded by nvim-lspconfig
    dependencies = {
      "mason-org/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "clangd",
        "omnisharp",
        "lua_ls",
        "pyright",
        "rust_analyzer",
        "gopls",
        "zls", -- not the Arch package: zls must match the zig version

        -- Web
        "html",
        "cssls",
        "ts_ls",
        "eslint",
        "jsonls",
      },
    },
  },

  -- LSP: server defaults come from nvim-lspconfig, mason-lspconfig enables
  -- every installed server, and blink.cmp adds completion capabilities
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },

    dependencies = {
      "mason-org/mason-lspconfig.nvim",
    },
  },

  -- Lua LSP knows the Neovim API and your installed plugins (replaces globals = { "vim" })
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },
}

return {
  -- BetterSQL.nvim
  {
    "w0x7y/better-sql.nvim",
    main = "better_sql",
    lazy = false,
    opts = {
      python = vim.fn.expand("~/.local/share/better-sql-venv/bin/python"),
      connections = {
        supabase = "service=supabase", -- host/user live in ~/.pg_service.conf, password in ~/.pgpass
      },
    },
  },
}

return {
  -- Auto-completion (also sets LSP completion capabilities for every server)
  {
    "saghen/blink.cmp",
    version = "1.*", -- release tags ship the prebuilt fuzzy matcher
    dependencies = {
      -- HTML / CSS / JS snippets; blink also loads the Revo snippets in snippets/
      "rafamadriz/friendly-snippets",
    },
    opts = {
      -- Enter confirms only if you selected something; Tab = next completion/snippet
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },

      -- Minimal look: plain list of label + kind, no border, no scrollbar,
      -- no popups unless asked (<C-space> toggles docs, built-in <C-s> shows the signature)
      completion = {
        list = { selection = { preselect = false } },
        menu = {
          border = "none",
          scrollbar = false,
          draw = { columns = { { "label" }, { "kind" } } },
        },
        documentation = { auto_show = false },
      },

      signature = { enabled = false },

      -- The built-in wildmenu completes the command line (see lua/config/finder.lua)
      cmdline = { enabled = false },

      -- Snippets only show after an @ (@for); the normal menu has none
      sources = {
        default = function()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local after_at = vim.api.nvim_get_current_line():sub(1, col):find("@[^%s@]*$")
          return after_at and { "snippets" } or { "lsp", "path", "buffer" }
        end,
        providers = {
          lsp = {
            transform_items = function(_, items)
              local snippet = require("blink.cmp.types").CompletionItemKind.Snippet
              return vim.tbl_filter(function(item)
                return item.kind ~= snippet
              end, items)
            end,
          },
          snippets = {
            -- Stretch each snippet's edit back over the @ so expanding replaces "@for", not just "for"
            transform_items = function(ctx, items)
              local at = ctx.line:sub(1, ctx.cursor[2]):find("@[^%s@]*$")
              for _, item in ipairs(at and items or {}) do
                item.textEdit.range.start.character = at - 1
              end
              return items
            end,
          },
        },
      },
    },
  },
}

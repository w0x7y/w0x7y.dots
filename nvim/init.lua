-- Leader key, set before lazy.nvim reads the plugin keymaps
vim.g.mapleader = " "

require("config.options")
require("config.finder")
require("config.lsp")
require("config.lazy")
require("config.revo")

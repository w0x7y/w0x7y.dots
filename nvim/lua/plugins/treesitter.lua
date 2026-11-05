return {
	-- Treesitter
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",

		config = function()
			local ts = require("nvim-treesitter")

			ts.setup()

			ts.install({
				-- General
				"lua",
				"python",
				"rust",
				"c",
				"cpp",
				"c_sharp",
				"zig",
				"go",
				"gomod",
				"gosum",
				"gowork",

				-- Shell / config / git
				"bash",
				"fish",
				"toml",
				"sql",
				"diff",
				"gitcommit",
				"regex",

				-- Web
				"html",
				"css",
				"javascript",
				"typescript",
				"tsx",
				"json", -- also highlights .jsonc files
				"yaml",
				"markdown",
				"markdown_inline",
			})

			-- Treesitter highlighting, indenting and folding for every filetype that has a parser
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					if pcall(vim.treesitter.start) then
						vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
						vim.wo.foldmethod = "expr"
						vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
					end
				end,
			})
		end,
	},
}

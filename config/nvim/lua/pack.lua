vim.pack.add({
	"https://github.com/bluz71/vim-moonfly-colors",
	"https://github.com/nvim-mini/mini.nvim",
	"https://github.com/Saghen/blink.lib",
	"https://github.com/Saghen/blink.cmp",
	"https://github.com/rafamadriz/friendly-snippets",
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
	"https://github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/tpope/vim-fugitive",
	"https://github.com/nvim-lua/plenary.nvim",
	{ src = "https://github.com/ThePrimeagen/harpoon", version = "harpoon2" },
	"https://github.com/christoomey/vim-tmux-navigator",
	"https://github.com/nvim-lualine/lualine.nvim",
	"https://github.com/stevearc/conform.nvim",
	"https://github.com./folke/snacks.nvim",
})

require("plugins.mini-icons")
require("plugins.mini-files")
require("plugins.mini-notify")
require("plugins.mini-cmdline")
require("plugins.mini-surround")
require("plugins.mini-pairs")
-- require("plugins.mini-animate")
require("plugins.mini-pick")
require("plugins.mini-snippets")
require("plugins.mini-diff")
require("plugins.harpoon")
require("plugins.snacks")
require("plugins.blink-cmp")
require("plugins.conform")
require("plugins.lsp")
require("plugins.css-definition").setup()
require("plugins.treesitter")
require("plugins.lualine")
require("plugins.mini-clue")

vim.pack.add({
    "https://github.com/bluz71/vim-moonfly-colors",
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/rafamadriz/friendly-snippets",
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", branch = "main" },
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/tpope/vim-fugitive",
    "https://github.com/nvim-lualine/lualine.nvim",
})

require("plugins.mini-files")
require("plugins.mini-notify")
require("plugins.mini-cmdline")
require("plugins.mini-surround")
require("plugins.mini-pick")
require("plugins.mini-completion")
require("plugins.mini-snippets")
require("plugins.mini-diff")
require("plugins.lsp")
require("plugins.treesitter")
require("plugins.lualine")

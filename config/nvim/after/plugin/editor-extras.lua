local safe = require("config.safe")

local mini_pairs = safe.require("mini.pairs", "mini.pairs")
if mini_pairs then
    mini_pairs.setup()
end

local ts_comments = safe.require("ts-comments", "ts-comments.nvim")
if ts_comments then
    ts_comments.setup()
end

local gitsigns = safe.require("gitsigns", "gitsigns.nvim")
if gitsigns then
    gitsigns.setup({
        current_line_blame = true,
        current_line_blame_opts = {
            delay = 500,
        },
    })
end

local trouble = safe.require("trouble", "trouble.nvim")
if trouble then
    trouble.setup({})
    vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
    vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
    vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
    vim.keymap.set("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP references" })
end

local autotag = safe.require("nvim-ts-autotag", "nvim-ts-autotag")
if autotag then
    autotag.setup()
end

local bufferline = safe.require("bufferline", "bufferline.nvim")
if bufferline then
    bufferline.setup({
        options = {
            diagnostics = "nvim_lsp",
            separator_style = "thin",
        },
    })
    vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
    vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
end

local snacks = safe.require("snacks", "snacks.nvim")
if snacks then
    snacks.setup({
        bigfile = { enabled = true },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
    })
end


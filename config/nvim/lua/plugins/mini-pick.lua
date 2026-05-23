local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")

MiniPick.setup({
    mappings = {
        move_down = "<C-j>",
        move_up = "<C-k>",
    },
})
MiniExtra.setup()

vim.keymap.set("n", "<leader>ff", function()
    MiniPick.builtin.files()
end, { desc = "Mini File Picker" })

vim.keymap.set("n", "<leader>fw", function()
    MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
end, { desc = "Grep word/Search word" })

vim.keymap.set("n", "<leader>fs", function()
    MiniPick.builtin.grep_live()
end, { desc = "Live grep" })

vim.keymap.set("n", "<leader>vh", function()
    MiniPick.builtin.help()
end, { desc = "Mini Help" })

vim.keymap.set("n", "<leader>xx", function()
    MiniExtra.pickers.diagnostic()
end, { desc = "Mini Picker Diagnostics" })

vim.keymap.set("n", "<leader>fk", function()
    MiniExtra.pickers.keymaps()
end, { desc = "Search keymaps" })

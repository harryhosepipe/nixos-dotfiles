local MiniDiff = require("mini.diff")

MiniDiff.setup({
    source = MiniDiff.gen_source.git({ index = false }),
    view = {
        style = "sign",
        signs = {
            add = "┃",
            change = "┃",
            delete = "_",
        },
    },
})

vim.keymap.set("n", "<leader>gg", "<cmd>tabnew | Git | only<cr>", { desc = "Fugitive Full Page New Tab" })
vim.keymap.set("n", "<leader>gd", function()
    if vim.wo.diff then
        vim.cmd("diffoff!")
        vim.cmd("only")
    else
        vim.cmd("Gvdiffsplit!")
    end
end, { desc = "Toggle Git diff split" })
vim.keymap.set("n", "<leader>go", MiniDiff.toggle_overlay, { desc = "Toggle Git diff overlay" })

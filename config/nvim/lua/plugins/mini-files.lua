local MiniFiles = require("mini.files")

MiniFiles.setup({
    mappings = {
        go_in = "L",
        go_in_plus = "<CR>",
        go_out = "_",
        go_out_plus = "H",
    },
})

vim.keymap.set("n", "<leader>e", function()
    if not MiniFiles.close() then
        MiniFiles.open()
    end
end, { desc = "Toggle mini file explorer" })

vim.keymap.set("n", "<leader>-", function()
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
end, { desc = "Toggle into currently opened file" })

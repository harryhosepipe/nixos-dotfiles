local colorpicker = require("config.safe").require("nvim-colorpicker", "nvim-colorpicker")

if not colorpicker then
    return
end

colorpicker.setup({
    alpha_enabled = true,
    presets = { "web", "tailwind" },
    highlight = {
        enable = true,
        filetypes = { "css", "scss", "html", "lua", "nix" },
    },
})

vim.keymap.set("n", "<leader>cp", "<Plug>(colorpicker)", { desc = "Color Picker" })
vim.keymap.set("n", "<leader>cc", "<Plug>(colorpicker-at-cursor)", { desc = "Pick Color at Cursor" })
vim.keymap.set("n", "<leader>cm", "<Plug>(colorpicker-mini)", { desc = "Mini Color Picker" })
vim.keymap.set("n", "<leader>ch", "<Plug>(colorpicker-highlight-toggle)", { desc = "Toggle Color Highlighting" })

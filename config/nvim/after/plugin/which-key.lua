local which_key = require("config.safe").require("which-key", "which-key.nvim")

if not which_key then
    return
end

which_key.setup({
    delay = 300,
})

which_key.add({
    { "<leader>c", group = "Code" },
    { "<leader>f", group = "Find" },
    { "<leader>l", group = "LSP" },
    { "<leader>m", group = "Make" },
    { "<leader>r", group = "Reload" },
})

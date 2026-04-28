local safe = require("config.safe")

local telescope = safe.require("telescope")
local actions = safe.require("telescope.actions", "telescope.nvim")
local builtin = safe.require("telescope.builtin", "telescope.nvim")

if not (telescope and actions and builtin) then
    return
end

telescope.setup({
    defaults = {
        mappings = {
            i = {
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-j>"] = actions.move_selection_next,
                ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            },
        },
    },
})
vim.keymap.set("n", "<leader>ff", builtin.find_files)
vim.keymap.set("n", "<leader>fo", builtin.oldfiles)
vim.keymap.set("n", "<leader>fq", builtin.quickfix)
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fg", function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
vim.keymap.set("n", "<leader>fc", function()
    builtin.grep_string({ search = vim.fn.expand("%:t:r") })
end, { desc = "Find current file" })
vim.keymap.set("n", "<leader>fs", function()
    builtin.grep_string({})
end, { desc = "Find current string" })
vim.keymap.set("n", "<leader>fi", function()
    builtin.find_files({ cwd = "~/.config/nvim/" })
end)

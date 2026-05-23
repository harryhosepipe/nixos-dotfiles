local safe = require("config.safe")
local harpoon = safe.require("harpoon")

if not harpoon then
    return
end

harpoon:setup()

vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
vim.keymap.set("n", "<C-p>", function() harpoon:list():prev() end)
vim.keymap.set("n", "<C-n>", function() harpoon:list():next() end)

vim.keymap.set("n", "<leader>fl", function()
    local telescope_config = safe.require("telescope.config", "telescope.nvim")
    local telescope_themes = safe.require("telescope.themes", "telescope.nvim")
    local telescope_pickers = safe.require("telescope.pickers", "telescope.nvim")
    local telescope_finders = safe.require("telescope.finders", "telescope.nvim")

    if not (telescope_config and telescope_themes and telescope_pickers and telescope_finders) then
        return
    end

    local conf = telescope_config.values
    local file_paths = {}
    for _, item in ipairs(harpoon:list().items) do
        table.insert(file_paths, item.value)
    end
    telescope_pickers.new(telescope_themes.get_ivy({ prompt_title = "Working List" }), {
        finder = telescope_finders.new_table({ results = file_paths }),
        previewer = conf.file_previewer({}),
        sorter = conf.generic_sorter({}),
    }):find()
end, { desc = "Open harpoon window" })

local harpoon = require("harpoon")

harpoon:setup()

vim.keymap.set("n", "<leader>ha", function()
	harpoon:list():add()
end, { desc = "Add file to Harpoon" })

vim.keymap.set("n", "<leader>hh", function()
	harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Show Harpoon files" })

for index = 1, 4 do
	vim.keymap.set("n", "<leader>h" .. index, function()
		harpoon:list():select(index)
	end, { desc = "Open Harpoon file " .. index })
end

vim.keymap.set("n", "<leader>hp", function()
	harpoon:list():prev()
end, { desc = "Previous Harpoon file" })

vim.keymap.set("n", "<leader>hn", function()
	harpoon:list():next()
end, { desc = "Next Harpoon file" })

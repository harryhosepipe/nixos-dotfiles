local function attached_language_servers()
	local names = {}

	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		table.insert(names, client.name)
	end

	table.sort(names)
	return names
end

local function has_attached_language_server()
	return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
end

local function show_language_servers(_, button)
	if button ~= "l" then
		return
	end

	local names = attached_language_servers()
	local message = #names > 0 and table.concat(names, "\n") or "None attached to this buffer"

	vim.notify(message, vim.log.levels.INFO, {
		title = "Language servers",
	})
end

require("lualine").setup({
	options = {
		theme = "moonfly",
		globalstatus = true,
		disabled_filetypes = {
			statusline = { "dashboard", "snacks_dashboard" },
		},
		component_separators = { left = "│", right = "│" },
		section_separators = { left = "", right = "" },
	},
	sections = {
		lualine_a = {
			"mode",
		},
		lualine_b = {
			{ "branch", icon = "" },
			{
				"diff",
				symbols = { added = "+", modified = "~", removed = "-" },
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				file_status = true,
				newfile_status = true,
				symbols = {
					modified = " ●",
					readonly = " ",
					unnamed = "[No Name]",
					newfile = " ",
				},
			},
		},
		lualine_x = {
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				sections = { "error", "warn" },
				symbols = { error = " ", warn = " " },
				update_in_insert = false,
			},
			{
				"encoding",
				cond = function()
					return vim.bo.fileencoding ~= "" and vim.bo.fileencoding ~= "utf-8"
				end,
			},
			{
				"fileformat",
				cond = function()
					return vim.bo.fileformat ~= "unix"
				end,
			},
			{
				function()
					return "󰒋"
				end,
				color = function()
					return { fg = has_attached_language_server() and "#36c692" or "#6f737b" }
				end,
				on_click = show_language_servers,
				padding = { left = 1, right = 1 },
			},
			{ "filetype", icon_only = false },
		},
		lualine_y = {
			{ "progress" },
		},
		lualine_z = {
			{ "location", padding = { left = 1, right = 1 } },
		},
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = {
			{ "filename", path = 1 },
		},
		lualine_x = {
			{ "location" },
		},
		lualine_y = {},
		lualine_z = {},
	},
	extensions = { "quickfix", "man" },
})

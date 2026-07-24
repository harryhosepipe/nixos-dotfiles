local colors = {
	green = "#36c692",
	red = "#ff5454",
	yellow = "#e3c78a",
}

local conform = require("conform")

local function window_is_wide()
	return vim.o.columns > 100
end

local function lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return "󰅚 no lsp"
	end

	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end
	table.sort(names)

	return "󰒋 " .. table.concat(names, ", ")
end

local function formatter_status()
	local names = {}
	for _, formatter in ipairs(conform.list_formatters(0)) do
		if formatter.available then
			table.insert(names, formatter.name)
		end
	end

	if #names == 0 then
		return ""
	end

	return "󰉼 " .. table.concat(names, ", ")
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
			{
				"mode",
				fmt = function(mode)
					return mode:sub(1, 1)
				end,
			},
		},
		lualine_b = {
			{ "branch", icon = "" },
			{
				"diff",
				symbols = { added = " ", modified = " ", removed = " " },
				cond = window_is_wide,
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
				sections = { "error", "warn", "info", "hint" },
				symbols = { error = " ", warn = " ", info = " ", hint = "󰌵 " },
				update_in_insert = false,
			},
			{
				formatter_status,
				cond = window_is_wide,
				color = { fg = colors.yellow },
			},
			{
				lsp_status,
				cond = window_is_wide,
				color = function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					return { fg = #clients > 0 and colors.green or colors.red }
				end,
			},
			{ "encoding", cond = window_is_wide },
			{ "fileformat", cond = window_is_wide },
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

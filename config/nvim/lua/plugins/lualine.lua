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

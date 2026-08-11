local M = {}

local file_globs = {
	"*.css",
	"*.pcss",
	"*.postcss",
	"*.astro",
	"*.svelte",
}

local function escape_pattern(text)
	return (text:gsub("([^%w])", "\\%1"))
end

local function class_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local column = vim.api.nvim_win_get_cursor(0)[2] + 1
	local in_class_attribute = false

	for _, quote in ipairs({ '"', "'" }) do
		local offset = 1
		while true do
			local start_match, end_match, name =
				line:find("([%w:_-]+)%s*=%s*" .. quote .. "[^" .. quote .. "]*" .. quote, offset)
			if not start_match then
				break
			end

			local value_start = assert(line:find(quote, start_match, true)) + 1
			local value_end = end_match - 1
			if (name == "class" or name == "className") and column >= value_start and column <= value_end then
				in_class_attribute = true
				break
			end

			offset = end_match + 1
		end
	end

	if not in_class_attribute then
		return nil
	end

	local start_column = column
	local end_column = column

	while start_column > 1 and line:sub(start_column - 1, start_column - 1):match("[%w_-]") do
		start_column = start_column - 1
	end

	while end_column <= #line and line:sub(end_column, end_column):match("[%w_-]") do
		end_column = end_column + 1
	end

	local class_name = line:sub(start_column, end_column - 1)
	if class_name == "" then
		return nil
	end

	return class_name
end

function M.find(class_name, root)
	local pattern = "(?<![A-Za-z0-9_-])\\." .. escape_pattern(class_name) .. "(?![A-Za-z0-9_-])"
	local command = { "rg", "--pcre2", "--vimgrep", "--color=never" }

	for _, glob in ipairs(file_globs) do
		vim.list_extend(command, { "--glob", glob })
	end

	vim.list_extend(command, {
		"--glob",
		"!node_modules/**",
		"--glob",
		"!dist/**",
		"--glob",
		"!build/**",
		"--glob",
		"!.git/**",
		pattern,
		root,
	})

	local result = vim.system(command, { text = true }):wait()
	if result.code ~= 0 and result.code ~= 1 then
		vim.notify("CSS definition search failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
		return {}
	end

	local definitions = {}
	for entry in (result.stdout or ""):gmatch("[^\r\n]+") do
		local filename, lnum, col, text = entry:match("^(.*):(%d+):(%d+):(.*)$")
		local trimmed = text and vim.trim(text)
		local is_comment = trimmed and (trimmed:match("^/%*") or trimmed:match("^%*") or trimmed:match("^//"))
		if filename and not is_comment then
			table.insert(definitions, {
				filename = filename,
				lnum = tonumber(lnum),
				col = tonumber(col),
				text = trimmed,
			})
		end
	end

	return definitions
end

local function jump_to(definition)
	vim.cmd.edit(vim.fn.fnameescape(definition.filename))
	vim.api.nvim_win_set_cursor(0, { definition.lnum, definition.col - 1 })
	vim.cmd("normal! zz")
end

local function go_to_css_definition()
	local class_name = class_under_cursor()
	if not class_name then
		vim.lsp.buf.definition()
		return
	end

	local root = vim.fs.root(0, { ".git", "package.json" }) or vim.uv.cwd()
	local definitions = M.find(class_name, root)

	if #definitions == 0 then
		vim.notify("No CSS definition found for ." .. class_name, vim.log.levels.INFO)
	elseif #definitions == 1 then
		jump_to(definitions[1])
	else
		vim.fn.setqflist({}, " ", {
			title = "CSS definitions for ." .. class_name,
			items = definitions,
		})
		vim.cmd.copen()
		vim.keymap.set("n", "<CR>", function()
			vim.cmd("cc")
			vim.cmd("normal! zz")
		end, { buffer = true, desc = "Jump to centered CSS definition" })
	end
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = { "astro", "svelte", "html" },
		callback = function(args)
			vim.keymap.set("n", "gd", go_to_css_definition, {
				buffer = args.buf,
				desc = "Go to CSS class or LSP definition",
			})
		end,
	})
end

return M

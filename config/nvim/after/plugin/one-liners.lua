local safe = require("config.safe")

local lualine = safe.require("lualine")
if lualine then
    lualine.setup({ options = { theme = "tokyonight" } })
end

local highlight_colors = safe.require("nvim-highlight-colors")
if highlight_colors then
    highlight_colors.setup({})
end

local orgmode = safe.require("orgmode")
if orgmode then
    orgmode.setup({
        org_agenda_files = "~/orgfiles/**/*",
        org_default_notes_file = "~/orgfiles/refile.org",
    })
end

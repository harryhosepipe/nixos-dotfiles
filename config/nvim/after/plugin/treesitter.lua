vim.filetype.add({ extension = { goon = "goon" } })

local safe = require("config.safe")
local treesitter = safe.require("nvim-treesitter")
local textobjects = safe.require("nvim-treesitter-textobjects")
local treesitter_context = safe.require("treesitter-context")

if not treesitter then
    return
end

-- nixCats installs the parser set up front, so this file only turns features on.
treesitter.setup({
    highlight = {
        enable = true,
    },
    indent = {
        enable = true,
    },
})

if textobjects then
    textobjects.setup({
        select = {
            lookahead = true,
        },
    })
end

vim.keymap.set({ "x", "o" }, "af", function()
    local select = safe.require("nvim-treesitter-textobjects.select")
    if select then
        select.select_textobject("@function.outer", "textobjects")
    end
end)
vim.keymap.set({ "x", "o" }, "if", function()
    local select = safe.require("nvim-treesitter-textobjects.select")
    if select then
        select.select_textobject("@function.inner", "textobjects")
    end
end)

if treesitter_context then
    treesitter_context.setup({})
end

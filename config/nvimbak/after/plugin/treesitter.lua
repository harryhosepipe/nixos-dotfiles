vim.filetype.add({ extension = { goon = "goon" } })

local safe = require("config.safe")
local treesitter = safe.require("nvim-treesitter")
local textobjects = safe.require("nvim-treesitter-textobjects")
local treesitter_context = safe.require("treesitter-context")

if not treesitter then
    return
end

-- nixCats installs the parser set up front. Newer nvim-treesitter exposes
-- queries and parser management; Neovim itself starts highlighting.
treesitter.setup({})

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("config-treesitter", { clear = true }),
    pattern = {
        "astro",
        "bash",
        "c",
        "c3",
        "css",
        "d",
        "dockerfile",
        "gitignore",
        "go",
        "haskell",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "lua",
        "markdown",
        "nix",
        "php",
        "python",
        "query",
        "rust",
        "svelte",
        "templ",
        "toml",
        "typescript",
        "typescriptreact",
        "vim",
        "vimdoc",
        "yaml",
        "zig",
    },
    callback = function(args)
        pcall(vim.treesitter.start, args.buf)
        vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
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

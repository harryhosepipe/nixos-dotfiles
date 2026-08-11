local function show_lsp_completions()
    local show = function()
        require("blink.cmp").show({ providers = { "lsp" } })
    end

    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
        show()
    else
        vim.cmd("startinsert")
        vim.schedule(show)
    end
end

require("blink.cmp").setup({
    keymap = {
        preset = "default",
        ["<C-Space>"] = {
            function()
                show_lsp_completions()
                return true
            end,
        },
        ["<M-Space>"] = {
            function()
                show_lsp_completions()
                return true
            end,
        },
        ["<C-s>"] = {
            function()
                show_lsp_completions()
                return true
            end,
        },
        ["<C-x><C-o>"] = {
            function()
                show_lsp_completions()
                return true
            end,
        },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-l>"] = { "select_prev", "fallback" },
        ["<CR>"] = {
            "select_and_accept",
            "fallback",
        },
    },
    completion = {
        list = {
            selection = {
                preselect = false,
                auto_insert = false,
            },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 500,
            treesitter_highlighting = false,
        },
    },
    sources = {
        default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
        implementation = "lua",
    },
})

vim.api.nvim_create_user_command("LspComplete", show_lsp_completions, {
    desc = "Show LSP-only completions with blink.cmp",
})

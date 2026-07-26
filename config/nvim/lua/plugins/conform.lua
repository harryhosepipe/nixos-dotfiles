local conform = require("conform")

conform.setup({
    format_on_save = {
        lsp_format = "fallback",
        timeout_ms = 500,
    },
    formatters_by_ft = {
        lua = { "stylua" },
        nix = { "alejandra" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        astro = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        markdown = { "prettier" },
    },
})

vim.keymap.set("n", "<C-f>", function()
    conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format local buffer" })

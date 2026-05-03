local lint = require("config.safe").require("lint", "nvim-lint")

if not lint then
    return
end

lint.linters_by_ft = {
    astro = { "eslint_d" },
    bash = { "shellcheck" },
    css = { "stylelint" },
    html = { "htmlhint" },
    javascript = { "eslint_d" },
    javascriptreact = { "eslint_d" },
    python = { "ruff" },
    sh = { "shellcheck" },
    svelte = { "eslint_d" },
    typescript = { "eslint_d" },
    typescriptreact = { "eslint_d" },
}

local group = vim.api.nvim_create_augroup("my.lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = group,
    callback = function()
        lint.try_lint()
    end,
})

vim.keymap.set("n", "<leader>cL", function()
    lint.try_lint()
end, { desc = "Lint buffer" })

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

local stylelint_config_names = {
    "stylelint.config.js",
    "stylelint.config.mjs",
    "stylelint.config.cjs",
    ".stylelintrc",
    ".stylelintrc.json",
    ".stylelintrc.yaml",
    ".stylelintrc.yml",
    ".stylelintrc.js",
    ".stylelintrc.cjs",
}

local function has_stylelint_config(bufnr)
    local file = vim.api.nvim_buf_get_name(bufnr)
    local start = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()

    return vim.fs.find(stylelint_config_names, {
        upward = true,
        path = start,
    })[1] ~= nil
end

local function try_lint()
    if vim.bo.filetype == "css" and not has_stylelint_config(0) then
        return
    end

    lint.try_lint()
end

local group = vim.api.nvim_create_augroup("my.lint", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = group,
    callback = function()
        try_lint()
    end,
})

vim.keymap.set("n", "<leader>cL", function()
    try_lint()
end, { desc = "Lint buffer" })

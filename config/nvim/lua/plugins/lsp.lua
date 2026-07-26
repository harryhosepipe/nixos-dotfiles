require("mason").setup()

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "df", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

vim.diagnostic.config({ virtual_text = true })

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require("blink.cmp").get_lsp_capabilities(capabilities)

vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
        },
    },
})

local typescript_root = vim.fn.fnamemodify(vim.uv.fs_realpath(vim.fn.exepath("tsc")) or "", ":h:h")
local typescript_node_modules = typescript_root .. "/lib/node_modules"
local typescript_tsdk = typescript_node_modules .. "/typescript/lib"

vim.lsp.config("astro", {
    cmd = {
        "env",
        "NODE_PATH=" .. typescript_node_modules,
        "astro-ls",
        "--stdio",
    },
    init_options = {
        typescript = {
            tsdk = typescript_tsdk,
        },
    },
})

vim.lsp.config("cssls", {
    settings = {
        css = { validate = true },
        scss = { validate = true },
        less = { validate = true },
    },
})

vim.lsp.config("css_variables", {
    filetypes = { "css", "scss", "less", "astro", "svelte" },
})

vim.lsp.config("tailwindcss", {
    -- The upstream config includes Markdown, which makes Tailwind scan the
    -- entire Git workspace when editing documentation such as AGENTS.md.
    filetypes = {
        "astro",
        "css",
        "html",
        "javascript",
        "javascriptreact",
        "less",
        "scss",
        "svelte",
        "typescript",
        "typescriptreact",
        "vue",
    },
    settings = {
        tailwindCSS = {
            classAttributes = { "class", "className", "class:list", "ngClass" },
            classFunctions = { "clsx", "cn", "cva", "tw" },
        },
    },
})

vim.lsp.config("eslint", {
    settings = {
        experimental = {
            useFlatConfig = true,
        },
    },
})

vim.lsp.enable({
    "lua_ls",
    "eslint",
    "cssls",
    "css_variables",
    "tailwindcss",
    "emmet_language_server",
    "svelte",
    "astro",
    "marksman",
})

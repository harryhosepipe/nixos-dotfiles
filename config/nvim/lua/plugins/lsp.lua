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

vim.lsp.config("tailwindcss", {
    settings = {
        tailwindCSS = {
            classAttributes = { "class", "className", "class:list", "ngClass" },
            classFunctions = { "clsx", "cn", "cva", "tw" },
        },
    },
})

vim.lsp.enable({
    "lua_ls",
    "eslint",
    "cssls",
    "tailwindcss",
    "emmet_language_server",
    "svelte",
    "astro",
    "marksman",
})

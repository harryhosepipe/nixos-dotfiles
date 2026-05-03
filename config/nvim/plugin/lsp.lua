vim.filetype.add({
    extension = {
        astro = "astro",
        h = "c",
        c3 = "c3",
        d = "d",
        svelte = "svelte",
        templ = "templ",
    },
})

local safe = require("config.safe")
local lazydev = safe.require("lazydev", "lazydev.nvim")
if lazydev then
    lazydev.setup()
end

vim.lsp.config("*", {
    root_markers = { ".git" },
})

vim.diagnostic.config({
    virtual_text = true,
    severity_sort = true,
    float = {
        style = "minimal",
        border = "rounded",
        source = "if_many",
        header = "",
        prefix = "",
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.HINT] = "⚑",
            [vim.diagnostic.severity.INFO] = "»",
        },
    },
})

local orig_open_floating_preview = vim.lsp.util.open_floating_preview
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
    opts = opts or {}
    opts.border = opts.border or "rounded"
    opts.max_width = opts.max_width or 80
    opts.max_height = opts.max_height or 24
    opts.wrap = opts.wrap ~= false
    return orig_open_floating_preview(contents, syntax, opts, ...)
end

local cmp_nvim_lsp = safe.require("cmp_nvim_lsp")
local capabilities = cmp_nvim_lsp
    and cmp_nvim_lsp.default_capabilities()
    or vim.lsp.protocol.make_client_capabilities()

local function map_lsp_keys(buf)
    local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end

    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "go", vim.lsp.buf.type_definition, "Go to type definition")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "gs", vim.lsp.buf.signature_help, "Signature help")
    map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "<leader>cD", vim.diagnostic.setloclist, "Document diagnostics")
    map("n", "<leader>cR", vim.lsp.buf.references, "References")
    map("n", "<leader>cs", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>cF", function()
        vim.lsp.buf.format({ async = true })
    end, "Format buffer")
    map("n", "<F2>", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "x" }, "<F3>", function()
        vim.lsp.buf.format({ async = true })
    end, "Format")
    map("n", "<F4>", vim.lsp.buf.code_action, "Code action")
end

local function setup_document_highlight(client, buf)
    if not client:supports_method("textDocument/documentHighlight") then
        return
    end

    local group = vim.api.nvim_create_augroup("my.lsp.highlight", { clear = false })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = buf,
        group = group,
        callback = vim.lsp.buf.clear_references,
    })
end

local function setup_format_on_save(client, buf)
    local excluded_filetypes = { php = true, c = true, cpp = true }
    if client:supports_method("textDocument/willSaveWaitUntil") then
        return
    end
    if not client:supports_method("textDocument/formatting") then
        return
    end
    if excluded_filetypes[vim.bo[buf].filetype] then
        return
    end

    vim.api.nvim_create_autocmd("BufWritePre", {
        group = vim.api.nvim_create_augroup("my.lsp.format", { clear = false }),
        buffer = buf,
        callback = function()
            vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
        end,
    })
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("my.lsp", {}),
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        local buf = args.buf

        map_lsp_keys(buf)
        setup_document_highlight(client, buf)
        setup_format_on_save(client, buf)
    end,
})

local servers = {
    luals = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                diagnostics = { globals = { "vim" } },
                workspace = {
                    checkThirdParty = false,
                    library = vim.api.nvim_get_runtime_file("", true),
                },
                telemetry = { enable = false },
            },
        },
    },

    nil_ls = {
        cmd = { "nil" },
        filetypes = { "nix" },
        root_markers = { "flake.nix", "default.nix", ".git" },
        settings = {
            ["nil"] = {
                formatting = {
                    command = { "alejandra" },
                },
            },
        },
    },

    phpactor = {
        cmd = { "phpactor", "language-server" },
        filetypes = { "php" },
        root_markers = { "composer.json", ".git" },
    },

    cssls = {
        cmd = { "vscode-css-language-server", "--stdio" },
        filetypes = { "css", "scss", "less" },
        root_markers = { "package.json", ".git" },
        settings = {
            css = { validate = true },
            scss = { validate = true },
            less = { validate = true },
        },
    },

    html = {
        cmd = { "vscode-html-language-server", "--stdio" },
        filetypes = { "html" },
        root_markers = { "package.json", ".git" },
    },

    jsonls = {
        cmd = { "vscode-json-languageserver", "--stdio" },
        filetypes = { "json", "jsonc" },
        root_markers = { "package.json", ".git", "config.jsonc" },
    },

    ts_ls = {
        cmd = { "typescript-language-server", "--stdio" },
        filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
        },
        root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
        settings = {
            completions = {
                completeFunctionCalls = true,
            },
        },
    },

    eslint = {
        cmd = { "vscode-eslint-language-server", "--stdio" },
        filetypes = {
            "astro",
            "javascript",
            "javascriptreact",
            "svelte",
            "typescript",
            "typescriptreact",
        },
        root_markers = {
            "eslint.config.js",
            "eslint.config.mjs",
            "eslint.config.cjs",
            ".eslintrc",
            ".eslintrc.js",
            ".eslintrc.cjs",
            ".eslintrc.json",
            "package.json",
        },
    },

    svelte = {
        cmd = { "svelteserver", "--stdio" },
        filetypes = { "svelte" },
        root_markers = { "svelte.config.js", "svelte.config.mjs", "package.json", ".git" },
    },

    astro = {
        cmd = { "astro-ls", "--stdio" },
        filetypes = { "astro" },
        root_markers = { "astro.config.mjs", "astro.config.js", "package.json", ".git" },
        init_options = {
            typescript = {},
        },
    },

    bashls = {
        cmd = { "bash-language-server", "start" },
        filetypes = { "bash", "sh" },
        root_markers = { ".git" },
    },

    pyright = {
        cmd = { "pyright-langserver", "--stdio" },
        filetypes = { "python" },
        root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
        settings = {
            python = {
                analysis = {
                    autoSearchPaths = true,
                    typeCheckingMode = "basic",
                    useLibraryCodeForTypes = true,
                },
            },
        },
    },

    emmet_language_server = {
        cmd = { "emmet-language-server", "--stdio" },
        filetypes = {
            "astro",
            "css",
            "html",
            "javascriptreact",
            "svelte",
            "typescriptreact",
        },
        root_markers = { "package.json", ".git" },
    },

    gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_markers = { "go.mod", "go.work", ".git" },
        settings = {
            gopls = {
                analyses = {
                    unusedparams = false,
                    ST1003 = false,
                    ST1000 = false,
                },
                staticcheck = true,
            },
        },
    },

    templ = {
        cmd = { "templ", "lsp" },
        filetypes = { "templ" },
        root_markers = { "go.mod", ".git" },
    },

    rust_analyzer = {
        cmd = { "rust-analyzer" },
        filetypes = { "rust" },
        root_markers = { "Cargo.toml", "rust-project.json", ".git" },
        settings = {
            ["rust-analyzer"] = {
                cargo = { allFeatures = true },
                formatting = {
                    command = { "rustfmt" },
                },
            },
        },
    },

    clangd = {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=never",
            "--completion-style=detailed",
            "--query-driver=/nix/store/*-gcc-*/bin/gcc*,/nix/store/*-clang-*/bin/clang*,/run/current-system/sw/bin/cc*",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_markers = { "compile_commands.json", ".clangd", "configure.ac", "Makefile", ".git" },
        init_options = {
            fallbackFlags = { "-std=c23" },
        },
    },

    c3lsp = {
        cmd = { "c3-lsp" },
        filetypes = { "c3" },
        root_markers = { "project.json", ".git" },
    },

    serve_d = {
        cmd = { "serve-d" },
        filetypes = { "d" },
        root_markers = { "dub.sdl", "dub.json", ".git" },
    },

    hls = {
        cmd = { "haskell-language-server-wrapper", "--lsp" },
        filetypes = { "haskell", "lhaskell" },
        root_markers = { "stack.yaml", "cabal.project", "package.yaml", "*.cabal", "hie.yaml", ".git" },
        settings = {
            haskell = {
                formattingProvider = "fourmolu",
                plugin = {
                    semanticTokens = { globalOn = false },
                },
            },
        },
    },

    zls = {
        cmd = { "zls" },
        filetypes = { "zig", "zir" },
        root_markers = { "zls.json", "build.zig", ".git" },
        settings = {
            zls = {
                enable_build_on_save = true,
                build_on_save_step = "install",
                warn_style = false,
                enable_snippets = true,
            },
        },
    },
}

local function lsp_command_exists(config)
    local cmd = config and config.cmd
    local binary = type(cmd) == "table" and cmd[1] or cmd

    return binary == nil or vim.fn.executable(binary) == 1
end

for name, config in pairs(servers) do
    config.capabilities = config.capabilities or capabilities
    vim.lsp.config(name, config)

    if lsp_command_exists(config) then
        vim.lsp.enable(name)
    end
end

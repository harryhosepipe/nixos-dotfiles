local safe = require("config.safe")

local cmp = safe.require("cmp", "nvim-cmp")
local cmp_nvim_lsp = safe.require("cmp_nvim_lsp")
local cmp_path = safe.require("cmp_path")
local cmp_buffer = safe.require("cmp_buffer")

if not (cmp and cmp_nvim_lsp and cmp_path and cmp_buffer) then
    return
end

cmp_nvim_lsp.setup()
cmp.register_source("path", cmp_path.new())
cmp.register_source("buffer", cmp_buffer)

cmp.setup({
    preselect = cmp.PreselectMode.Item,
    completion = {
        completeopt = "menu,menuone,noinsert",
        autocomplete = { cmp.TriggerEvent.TextChanged },
    },
    window = { documentation = cmp.config.window.bordered() },
    mapping = cmp.mapping.preset.insert({
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
        ["<C-j>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item({ behavior = cmp.SelectBehavior.Select }) else fallback() end
        end, { "i", "s" }),
        ["<C-k>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select }) else fallback() end
        end, { "i", "s" }),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item() else fallback() end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function()
            if cmp.visible() then cmp.select_prev_item() end
        end, { "i", "s" }),
    }),
    sources = {
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "buffer", keyword_length = 3 },
    },
})

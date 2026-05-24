local function lsp_status()
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if #clients == 0 then
        return "󰅚"
    end

    local names = {}
    for _, client in ipairs(clients) do
        table.insert(names, client.name)
    end

    return "󰒋 " .. table.concat(names, ",")
end

require("lualine").setup({
    options = {
        theme = "moonfly",
        globalstatus = true,
        component_separators = "",
        section_separators = "",
    },
    sections = {
        lualine_x = {
            {
                lsp_status,
                color = function()
                    local clients = vim.lsp.get_clients({ bufnr = 0 })
                    return { fg = #clients > 0 and "#36c692" or "#ff5454" }
                end,
            },
            "encoding",
            "fileformat",
            "filetype",
        },
    },
})

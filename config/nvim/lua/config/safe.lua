local M = {}

function M.require(module, plugin_name)
    local ok, value = pcall(require, module)
    if ok then
        return value
    end

    local name = plugin_name or module
    vim.notify("Skipping " .. name .. ": plugin is not available", vim.log.levels.WARN)
    return nil
end

return M

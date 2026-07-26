local M = {}

local env_key = "NVIM_RESTART_FILE"

local function normal_file(buffer)
    if buffer <= 0 or vim.fn.buflisted(buffer) ~= 1 or vim.bo[buffer].buftype ~= "" then
        return nil
    end

    local name = vim.api.nvim_buf_get_name(buffer)
    if name ~= "" and vim.fn.filereadable(name) == 1 then
        return name
    end
end

local function last_file()
    local file = normal_file(vim.api.nvim_get_current_buf()) or normal_file(vim.fn.bufnr("#"))

    for _, oldfile in ipairs(vim.v.oldfiles) do
        if file ~= nil then
            break
        end

        if vim.fn.filereadable(oldfile) == 1 then
            file = oldfile
        end
    end

    return file
end

function M.restore()
    local restart_file = vim.env[env_key]

    if restart_file == nil or restart_file == "" then
        return
    end

    vim.env[env_key] = nil

    vim.schedule(function()
        if vim.fn.filereadable(restart_file) == 1 then
            vim.cmd.edit(vim.fn.fnameescape(restart_file))
        end
    end)
end

function M.restart_last_file()
    vim.env[env_key] = last_file()
    vim.cmd.restart()
end

return M

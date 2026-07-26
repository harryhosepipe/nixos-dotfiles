local MiniFiles = require("mini.files")

local show_hidden = false

local filter_show = function()
    return true
end

local filter_hide = function(fs_entry)
    return fs_entry.name == ".env" or not vim.startswith(fs_entry.name, ".")
end

local current_filter = function()
    return show_hidden and filter_show or filter_hide
end

local toggle_hidden = function()
    show_hidden = not show_hidden
    MiniFiles.refresh({
        content = {
            filter = current_filter(),
        },
    })
end

local synchronize_without_confirm_except_delete = function()
    local original_confirm = vim.fn.confirm

    vim.fn.confirm = function(msg, choices, default, type)
        if msg:find("DELETE", 1, true) then
            return original_confirm(msg, choices, default, type)
        end

        return 1
    end

    local ok, result = pcall(MiniFiles.synchronize)
    vim.fn.confirm = original_confirm

    if not ok then
        error(result)
    end

    return result
end

MiniFiles.setup({
    content = {
        filter = function(fs_entry)
            return current_filter()(fs_entry)
        end,
    },
    mappings = {
        go_in = "L",
        go_in_plus = "<CR>",
        go_out = "_",
        go_out_plus = "",
        synchronize = "",
    },
})

vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesBufferCreate",
    callback = function(args)
        vim.keymap.set("n", "H", toggle_hidden, {
            buffer = args.data.buf_id,
            desc = "Toggle hidden files",
        })

        vim.keymap.set("n", "<C-l>", MiniFiles.go_in, {
            buffer = args.data.buf_id,
            desc = "Enter directory",
        })

        vim.keymap.set("n", "<C-h>", MiniFiles.go_out, {
            buffer = args.data.buf_id,
            desc = "Leave directory",
        })

        vim.keymap.set("n", "<leader>w", synchronize_without_confirm_except_delete, {
            buffer = args.data.buf_id,
            desc = "Apply file changes",
        })
    end,
})

vim.keymap.set("n", "<leader>e", function()
    if not MiniFiles.close() then
        MiniFiles.open()
    end
end, { desc = "Toggle mini file explorer" })

vim.keymap.set("n", "<leader>-", function()
    MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
    MiniFiles.reveal_cwd()
end, { desc = "Toggle into currently opened file" })

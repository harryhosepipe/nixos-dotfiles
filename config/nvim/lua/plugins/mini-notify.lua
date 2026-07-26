require("mini.notify").setup({
    -- Only show messages.
    content = {
        format = function(notif)
            return notif.msg
        end,
    },
})

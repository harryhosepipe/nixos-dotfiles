local neo_tree = require("config.safe").require("neo-tree", "neo-tree.nvim")

if not neo_tree then
    return
end

neo_tree.setup({
    close_if_last_window = true,
    enable_git_status = false,
    enable_diagnostics = false,
    default_component_configs = {
        icon = {
            -- Show plain file names instead of Nerd Font symbols.
            -- This keeps the tree readable even when the terminal font
            -- does not match the icon set.
            enabled = false,
        },
        modified = {
            symbol = "",
        },
        git_status = {
            symbols = {
                added = "",
                deleted = "",
                modified = "",
                renamed = "",
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
            },
        },
    },
    filesystem = {
        follow_current_file = {
            enabled = true,
        },
        filtered_items = {
            visible = false,
            hide_dotfiles = true,
            hide_gitignored = false,
        },
    },
    window = {
        width = 32,
    },
})

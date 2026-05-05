# Neovim Setup

This is a custom Neovim setup.

NixCats installs the plugins and language tools from Nix. The Lua files in this
folder configure those plugins directly.

Main files:

- `init.lua`: starts the config.
- `lua/config/options.lua`: editor settings.
- `lua/config/keybinds.lua`: custom keymaps.
- `after/plugin/`: plugin setup files.
- `plugin/lsp.lua`: language server setup.
- `modules/home/editors/neovim-full.nix`: the NixCats package list.

This setup does not import LazyVim and does not use `lazy.nvim`.

## Useful Keys

- `<leader>e`: toggle the file tree.
- `<leader>ff`: find files.
- `<leader>fb`: list buffers.
- `<leader>fg`: search text.
- `<leader>u`: open Undotree.
- `<leader>rl`: reload Neovim config.
- `<leader>mm`: run `make`.
- `<leader>dg`: generate a doc comment from the current line.

## PHP Language Server

This repo uses `phpactor` for PHP language features because it is free in
Nixpkgs. `intelephense` is also a PHP language server, but Nix marks it as
unfree, so it would require changing the system's unfree package policy.

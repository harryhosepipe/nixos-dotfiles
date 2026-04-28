# Neovim LazyVim-Like Setup TODO

Goal: keep this as a custom NixCats Neovim setup, but add LazyVim-like behavior one small piece at a time.

Do not import `LazyVim/LazyVim`.
Do not use `lazy.nvim` as the plugin manager.
Add plugins through `modules/home/neovim.nix`, then configure them in `config/nvim/`.

## Ground Rules

- [ ] Change one plugin or feature group at a time.
- [ ] After each change, open Neovim and test that one thing before moving on.
- [ ] Prefer Nix-installed tools over Mason.
- [ ] Keep comments short and plain.
- [ ] If a plugin needs too much wiring, pause and write down why before adding it.

## Current Base

- [x] NixCats owns the Neovim package.
- [x] `config/nvim/init.lua` starts the custom Lua config.
- [x] Basic options live in `config/nvim/lua/config/options.lua`.
- [x] Basic keymaps live in `config/nvim/lua/config/keybinds.lua`.
- [x] Treesitter is installed through Nix.
- [x] Telescope is installed and configured.
- [x] nvim-cmp is installed and configured.
- [x] LSP is configured directly, without Mason.
- [x] Neo-tree is installed and configured.
- [x] Which-key is installed and configured.
- [x] Harpoon is installed and configured.
- [x] Tokyonight, lualine, orgmode, fugitive, undotree, and OSC yank are present.

## Phase 1: Make The Core Solid

- [x] Remove the old custom plugin downloader in `lua/manage.lua`.
  Why: NixCats should install plugins, not Lua cloning from GitHub.
  Test: start Neovim offline or with no network and confirm plugins still load.

- [x] Remove `lua/plugin-list.lua` if NixCats fully owns plugins.
  Why: one plugin list is easier to understand than two.
  Test: `nvim --headless '+messages' '+qall'` exits cleanly.

- [x] Make missing plugin setup fail softly.
  Why: if one plugin is missing, Neovim should show a useful message instead of exploding.
  Test: temporarily comment one plugin in Nix and confirm the error is readable.

- [x] Clean up `plugin/lsp.lua`.
  Why: this is the most important working layer for coding.
  Test: open Lua, Nix, PHP, Go, Rust, and TypeScript files and run `:checkhealth vim.lsp`.

- [x] Add LazyVim-like LSP key descriptions.
  Why: which-key should clearly show code actions, rename, diagnostics, and goto actions.
  Test: press `<leader>c` and `g` in a code file.

## Phase 2: Formatting And Linting

- [ ] Add `conform.nvim`.
  Why: LazyVim uses it as the main formatter layer.
  Test: format a Nix file with `alejandra` and a Lua file with `stylua`.

- [ ] Add format-on-save behind one clear setting.
  Why: it should be easy to turn automatic formatting on or off.
  Test: save a Nix file and confirm formatting runs only when enabled.

- [ ] Add `nvim-lint`.
  Why: LazyVim separates linting from language servers.
  Test: open a file with a known lint issue and confirm diagnostics appear.

- [ ] Decide whether PHP formatting stays as a keymap or moves into `conform.nvim`.
  Why: one formatting path is easier to learn.
  Test: format a PHP file with `php-cs-fixer`.

## Phase 3: Completion And Editing Helpers

- [ ] Decide whether to keep `nvim-cmp` or switch to `blink.cmp`.
  Why: current LazyVim defaults to Blink, but `nvim-cmp` is already working.
  Test: completion menu appears in Lua, Nix, and PHP files.

- [ ] Add `mini.pairs`.
  Why: LazyVim uses it for automatic closing brackets and quotes.
  Test: type `(`, `[`, `{`, `"`, and `'` in insert mode.

- [ ] Add `mini.ai`.
  Why: it gives better text objects, like selecting functions and arguments.
  Test: try `vaf`, `vif`, `vaa`, and `via` in code.

- [ ] Add `ts-comments.nvim`.
  Why: it improves comment behavior for mixed-language files.
  Test: comment lines in TSX, HTML, and Lua.

- [ ] Add `nvim-ts-autotag`.
  Why: it auto-closes and renames HTML/JSX tags.
  Test: edit an HTML or TSX tag pair.

## Phase 4: Search, Navigation, And Diagnostics

- [ ] Add `flash.nvim`.
  Why: LazyVim uses it for fast jump/search movement.
  Test: press `s` and jump to a visible match.

- [ ] Add `trouble.nvim`.
  Why: it gives a better diagnostics, quickfix, and symbol list.
  Test: open workspace diagnostics with a leader key.

- [ ] Add `todo-comments.nvim`.
  Why: it finds TODO, FIXME, HACK, and similar comments.
  Test: add a TODO comment and find it from a picker.

- [ ] Add `grug-far.nvim`.
  Why: LazyVim uses it for project-wide search and replace.
  Test: search and replace text in a small test project.

- [ ] Decide whether Telescope stays the main picker or Snacks picker replaces it.
  Why: LazyVim now defaults toward Snacks, but Telescope is already working.
  Test: find files, grep text, list buffers, and open old files.

## Phase 5: Git And Sessions

- [ ] Add `gitsigns.nvim`.
  Why: LazyVim shows changed lines and gives hunk actions.
  Test: edit a tracked file and check signs in the left column.

- [ ] Add `persistence.nvim`.
  Why: it restores previous sessions.
  Test: open files, restart Neovim, restore the session.

- [ ] Decide whether to add `lazygit` keymaps.
  Why: useful, but it adds another external tool.
  Test: press the git UI key and confirm it opens in a floating terminal.

## Phase 6: UI Polish

- [ ] Add `bufferline.nvim`.
  Why: LazyVim shows open buffers as tabs.
  Test: open several files and move between buffers.

- [ ] Add `noice.nvim`.
  Why: LazyVim uses it for command-line and message UI.
  Test: run commands, searches, and LSP hover without UI errors.

- [ ] Add `nui.nvim`.
  Why: it is a shared UI library needed by several plugins.
  Test: confirm plugins that depend on it load.

- [ ] Add `mini.icons`.
  Why: LazyVim uses it for file and UI icons.
  Test: file tree and picker icons render correctly.

- [ ] Decide whether to keep plain Neo-tree icons disabled.
  Why: plain text is more reliable if the terminal font is not ready.
  Test: file tree remains readable.

## Phase 7: Language Extras

- [ ] Add LazyVim-like Nix support.
  Why: this repo is NixOS-first.
  Test: open `.nix` files and check LSP, format, and syntax.

- [ ] Add LazyVim-like PHP support with `phpactor`.
  Why: PHP support should avoid unfree `intelephense`.
  Test: open PHP and check go-to-definition and diagnostics.

- [ ] Add LazyVim-like Go support.
  Why: Go needs `gopls`, format, imports, and extra test helpers if wanted.
  Test: open Go and check format/import behavior.

- [ ] Add LazyVim-like Rust support.
  Why: Rust needs `rust-analyzer` and sane settings.
  Test: open Rust and check hover, diagnostics, and format.

- [ ] Add LazyVim-like TypeScript support.
  Why: TypeScript needs good project root detection and completion.
  Test: open TS/TSX and check diagnostics and imports.

- [ ] Add LazyVim-like JSON/YAML support.
  Why: config files benefit from schemas and validation.
  Test: open JSON and YAML files and check diagnostics.

- [ ] Add LazyVim-like Markdown support.
  Why: markdown is common in this repo.
  Test: open README files and check highlighting.

## Phase 8: Optional Extras

- [ ] Add `mini.surround`.
  Why: useful editing helper, but not required first.
  Test: add/change/delete quotes around text.

- [ ] Add `yanky.nvim`.
  Why: LazyVim can keep yank history, but it changes paste behavior.
  Test: yank several values and open yank history.

- [ ] Add `inc-rename.nvim`.
  Why: nicer rename UI, but LSP rename already works.
  Test: rename a symbol.

- [ ] Add `overseer.nvim`.
  Why: task runner, useful after core editor behavior is stable.
  Test: run a project task.

- [ ] Add `neogen`.
  Why: doc generation plugin could replace the custom doc helper later.
  Test: generate docs for Lua, Go, Rust, and Python.

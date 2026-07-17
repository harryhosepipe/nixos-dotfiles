# Neovim to Zed migration notes

This file records problems encountered while matching the Neovim configuration
in this repository to Zed.

## Scope

- `config/zed` is the tracked source and is deployed to `~/.config/zed`.
- The macOS live configuration was used to test changes before syncing them
  here.
- Language servers and extensions were out of scope for the initial migration.

## Resolved problems

### The dotfiles repository was edited during the migration

- Problem: migration notes, a keymap, and settings changes were initially added
  to the repository before the working configuration had been tested.
- Resolution: restored the repository, completed testing in `~/.config/zed`,
  then intentionally promoted the validated configuration to `config/zed`.

### Repository clone failed over SSH

- Problem: `gh repo clone` failed with `Host key verification failed`.
- Resolution: cloned the public repository over HTTPS without changing SSH
  configuration.

### Project panel toggled focus instead of closing

- Problem: `Space e` moved between the editor and project panel but did not
  close the focused panel.
- Resolution: use `project_panel::ToggleFocus` from the editor and
  `workspace::ToggleLeftDock` from `ProjectPanel && not_editing`.

### Pane navigation became trapped in the project panel

- Problem: `Ctrl-h/j/k/l` stopped working after focus entered the project panel.
- Resolution: added the same directional actions to the non-editing project
  panel context.

### Previous-tab action was deprecated

- Problem: `pane::ActivatePrevItem` produced a deprecated-keymap warning.
- Resolution: replaced it with `pane::ActivatePreviousItem`, as specified by
  Zed's official keymap migrator.

### Project text finder did not open from the editor

- Problem: `project_search::OpenTextFinder` did nothing when bound to
  `Space f s` in an editor.
- Cause: that action operates from an existing `ProjectSearchView`.
- Resolution: restored the working `workspace::NewSearch` action.

### Buffer-only diagnostics is unsupported

- Problem: Neovim's `Space x X` filters diagnostics to the current buffer.
- Resolution: left it unbound because `diagnostics::Deploy` exposes no active-
  buffer filter; project diagnostics and next/previous navigation are mapped.

### Invalid JSON was caught before deployment

- Problem: a clipboard-binding edit initially omitted a comma.
- Resolution: `jq empty` caught the error before the live keymap was replaced;
  the comma was added and validation rerun.

### Patch file boundaries were incorrect twice

- Problem: two local patches initially placed migration-document edits under
  the keymap file section and failed verification.
- Resolution: corrected the file boundaries and validated before deployment.

### Pi ACP could not be selected from the Agent Panel

- Problem: clicking `Select a Model` showed no Pi ACP option and Zed's log
  reported `no language model configured`.
- Cause: `Select a Model` configures Zed's built-in agent. External ACP agents
  are thread types and do not appear in that model picker.
- Resolution: open the new-agent-thread menu with `Cmd-Option-Shift-N`, select
  `pi ACP`, and start a separate external-agent thread. The working thread
  identifies itself as `pi v0.80.6` and its composer says `Message pi ACP`.
- Verification: Zed launched `npm exec pi-acp` and the adapter returned the
  expected response to a minimal round-trip prompt.

### Computer-use inspection initially failed

- Problem: the first `screencapture` attempt returned `could not create image
  from display`, Zed's GPUI controls were not exposed in the macOS accessibility
  tree, and one AppleScript probe incorrectly embedded `screencapture` as an
  AppleScript statement and produced a syntax error.
- Resolution: retried after screen-capture access was available, used global
  keyboard navigation for the GPUI menu, and ran screen capture as a separate
  shell command. One Down highlighted `Zed Agent`; two further Downs selected
  `pi ACP`.

### Git generated a machine-local commit identity

- Problem: the first commit used Git's automatically generated
  `pabbo@Minis-Mac-mini.local` address, which would not be associated with the
  GitHub account.
- Resolution: configured this checkout with the authenticated GitHub account's
  name and noreply address, then amended the commit with the corrected author.

## Migrated editor settings

- Relative line numbers
- Eight-line vertical scroll margin
- 80-column wrap guide
- Four-space indentation globally
- Two-space indentation for Nix and JSONC
- Smart-case search and centered search matches
- Current-line highlighting
- System clipboard integration
- Inconsolata Nerd Font Mono

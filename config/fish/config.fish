# Hide fish's default greeting so shell startup stays clean.
set -g fish_greeting

# Start the prompt theme.
oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source

# Load fzf's fuzzy search key shortcuts.
if test -f "$FZF_SHARE/key-bindings.fish"
  source "$FZF_SHARE/key-bindings.fish"
end

# Load shared picker functions and aliases from the repo.
source ~/.config/fish/functions.fish
source ~/.config/fish/aliases.fish

# Zoxide should be loaded last
zoxide init --cmd cd fish | source

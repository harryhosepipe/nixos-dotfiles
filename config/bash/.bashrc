# Start the prompt theme.
eval "$(oh-my-posh init bash --config ~/.config/oh-my-posh/config.json)"

# Load fzf's fuzzy search helpers for completion and key shortcuts.
if [ -f "$FZF_SHARE/completion.bash" ]; then
  . "$FZF_SHARE/completion.bash"
fi

if [ -f "$FZF_SHARE/key-bindings.bash" ]; then
  . "$FZF_SHARE/key-bindings.bash"
fi

# Load shared picker functions and aliases from the repo.
. ~/.config/bash/functions.sh
. ~/.config/bash/aliases.sh

# Zoxide should be loaded last
eval "$(zoxide init --cmd cd bash)"

# Load plugins first so they can add completions before Zsh turns completion on.
source ~/.config/zsh/plugins.zsh

# Turn on completion after plugin-provided completions are ready.
autoload -U compinit
compinit

# Start the prompt theme and helper tools.
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

# Load fzf's fuzzy search helpers for completion and key shortcuts.
if [ -f "$FZF_SHARE/completion.zsh" ]; then
  source "$FZF_SHARE/completion.zsh"
fi

if [ -f "$FZF_SHARE/key-bindings.zsh" ]; then
  source "$FZF_SHARE/key-bindings.zsh"
fi

# Load the shared functions and aliases from the repo.
source ~/.config/zsh/functions.zsh
source ~/.config/zsh/aliases.zsh

# Ensure GitHub SSH auth uses one long-running user agent.
if [[ $- == *i* ]]; then
  export SSH_AUTH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$UID}/ssh-agent"
  if [[ ! -S "$SSH_AUTH_SOCK" ]]; then
    systemctl --user start ssh-agent.service >/dev/null 2>&1
  fi
  if [[ -S "$SSH_AUTH_SOCK" ]] && ! ssh-add -l >/dev/null 2>&1; then
    ssh-add ~/.ssh/ansible_razer >/dev/null
  fi
fi

zle -N fzf_complete_and_accept
# Use Ctrl+F to accept the gray inline suggestion from zsh-autosuggestions.
# Tab still opens completion menus and fzf-based completion.
bindkey '^F' autosuggest-accept
bindkey '^[l' fzf_complete_and_accept

#History
# Keep shell history in the XDG state folder so config and saved state stay separate.
HISTDIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$HISTDIR"

HISTSIZE=5000
HISTFILE="$HISTDIR/history"
SAVEHIST=$HISTSIZE
HISTDUP=erase

# Move the old history file once so new shells stop writing to two places.
if [ ! -f "$HISTFILE" ] && [ -f "$HOME/.zsh_history" ]; then
  mv "$HOME/.zsh_history" "$HISTFILE"
fi

setopt appendhistory
setopt hist_fcntl_lock
setopt hist_save_by_copy
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt hist_reduce_blanks

#Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A=Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:*' fzf-flags --height=100%
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Zoxide should be loaded last.
eval "$(zoxide init --cmd cd zsh)"

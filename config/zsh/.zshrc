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
zle -N fzf_complete_and_accept
bindkey '^[l' fzf_complete_and_accept

#History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

#Completion Styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A=Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'


# Zoxide should be loaded last.
eval "$(zoxide init --cmd cd zsh)"

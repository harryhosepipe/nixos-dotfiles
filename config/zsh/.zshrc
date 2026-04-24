autoload -U compinit
compinit

eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/config.json)"

alias btw='echo i use nixos, btw'
alias nrs='sudo nixos-rebuild switch --flake '\''path:/home/pablo/dotfiles#nixos-btw'\'''

# Zoxide should be loaded last
eval "$(zoxide init --cmd cd zsh)"

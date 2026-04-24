set -g fish_greeting

oh-my-posh init fish --config ~/.config/oh-my-posh/config.json | source

alias btw 'echo i use nixos, btw'
alias nrs 'sudo nixos-rebuild switch --flake "path:/home/pablo/dotfiles#nixos-btw"'

# Zoxide should be loaded last
zoxide init --cmd cd fish | source

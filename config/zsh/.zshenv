export ZDOTDIR="$HOME/.config/zsh"

# Load the NixOS system environment for every zsh session.
# This keeps values like NIX_LD available even in terminals that do not start as login shells.
if [ -f /etc/set-environment ]; then
  . /etc/set-environment
fi

# Load Home Manager's shared environment values for every zsh session.
# This keeps tools like fzf, zoxide, and zinit available in the same shells.
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

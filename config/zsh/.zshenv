export ZDOTDIR="$HOME/.config/zsh"

# Load Home Manager's shared environment values for every zsh session.
# This keeps tools like fzf, zoxide, and zinit available even in non-login shells.
if [ -f "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh" ]; then
  . "/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

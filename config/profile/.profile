# Load the NixOS system environment first.
# This is where NIX_LD is exported for unpackaged binaries that tools like Mason download.
if [ -f /etc/set-environment ]; then
  . /etc/set-environment
fi

# Load Home Manager's shared environment values for login shells.
# This adds user-level values like CODEX_HOME and shell helper paths on top.
if [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
  . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

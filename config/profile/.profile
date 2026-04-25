# Load Home Manager's shared environment values for login shells.
# This is where settings like PATH and _ZO_ECHO get pulled into the shell.
if [ -f /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]; then
  . /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
fi

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

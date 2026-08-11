# Load the shared login profile first.
if [ -f "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi

# Then load the interactive bash setup only for interactive shells. Buzz uses
# many non-interactive login-shell probes; initializing prompts and fuzzy
# finders for each probe makes its runtime refresh overlap indefinitely.
if [[ $- == *i* ]] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

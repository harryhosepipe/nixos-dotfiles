# Load the shared login profile first.
if [ -f "$HOME/.profile" ]; then
  . "$HOME/.profile"
fi

# Then load the interactive bash setup.
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

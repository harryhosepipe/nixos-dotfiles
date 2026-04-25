# This is the plugin room for Zsh.
# Add new plugins here so the main .zshrc stays easy to read.

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [ ! -f "$ZINIT_HOME/zinit.zsh" ]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

if [ -f "$ZINIT_HOME/zinit.zsh" ]; then
  source "$ZINIT_HOME/zinit.zsh"

  # Load small helper plugins first.
  zinit ice wait"0" lucid
  zinit light zsh-users/zsh-autosuggestions

  zinit ice wait"0" lucid
  zinit light zsh-users/zsh-completions
  zinit light Aloxaf/fzf-tab

  # Keep syntax highlighting last because it needs to see the final command line.
  zinit light zsh-users/zsh-syntax-highlighting
fi

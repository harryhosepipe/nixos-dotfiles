ff() {
  local selected
  selected="$(find . -path '*/.git/*' -prune -o -type f -print | sed 's#^\./##' | fzf --prompt='file> ')"
  [ -n "$selected" ] && nvim "$selected"
}

fdot() {
  local selected
  selected="$(find "$HOME/dotfiles" -path '*/.git/*' -prune -o -type f -print | sed "s#^$HOME/dotfiles/##" | fzf --prompt='dotfiles> ')"
  [ -n "$selected" ] && nvim "$HOME/dotfiles/$selected"
}

fcd() {
  local selected
  selected="$(find . -path '*/.git/*' -prune -o -type d -print | sed 's#^\./##' | sed '/^$/d' | fzf --prompt='dir> ')"
  [ -n "$selected" ] && cd "$selected"
}

fbr() {
  local selected
  selected="$(git branch --format='%(refname:short)' 2>/dev/null | fzf --prompt='branch> ')"
  [ -n "$selected" ] && git switch "$selected"
}

fh() {
  local selected
  selected="$(history | sed 's/^[[:space:]]*[0-9]\+[[:space:]]*//' | awk 'NF && !seen[$0]++' | fzf --prompt='history> ')"
  [ -n "$selected" ] && eval "$selected"
}

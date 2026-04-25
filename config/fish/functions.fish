function ff
  set selected (find . -path '*/.git/*' -prune -o -type f -print | sed 's#^\./##' | fzf --prompt='file> ')
  if test -n "$selected"
    nvim "$selected"
  end
end

function fdot
  set selected (find "$HOME/dotfiles" -path '*/.git/*' -prune -o -type f -print | sed "s#^$HOME/dotfiles/##" | fzf --prompt='dotfiles> ')
  if test -n "$selected"
    nvim "$HOME/dotfiles/$selected"
  end
end

function fcd
  set selected (find . -path '*/.git/*' -prune -o -type d -print | sed 's#^\./##' | sed '/^$/d' | fzf --prompt='dir> ')
  if test -n "$selected"
    cd "$selected"
  end
end

function fbr
  set selected (git branch --format='%(refname:short)' 2>/dev/null | fzf --prompt='branch> ')
  if test -n "$selected"
    git switch "$selected"
  end
end

function fh
  set selected (history | awk 'NF && !seen[$0]++' | fzf --prompt='history> ')
  if test -n "$selected"
    eval "$selected"
  end
end

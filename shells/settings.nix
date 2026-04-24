{
  defaultShell = "zsh";

  sharedAliases = {
    btw = "echo i use nixos, btw";
    nrs = "sudo nixos-rebuild switch --flake 'path:/home/pablo/dotfiles#nixos-btw'";
  };

  sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];
}

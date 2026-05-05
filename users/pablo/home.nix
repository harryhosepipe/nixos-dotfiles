{userSettings, ...}: {
  imports =
    [
      ../../modules/home/base.nix
      ../../modules/home/cli.nix
      ../../modules/home/git.nix
    ]
    ++ (
      if userSettings.shell == "zsh"
      then [../../modules/home/shells/zsh.nix]
      else if userSettings.shell == "fish"
      then [../../modules/home/shells/fish.nix]
      else [../../modules/home/shells/bash.nix]
    )
    ++ (
      if userSettings.neovimProfile == "full"
      then [../../modules/home/editors/neovim-full.nix]
      else [../../modules/home/editors/neovim-lite.nix]
    )
    ++ (
      if userSettings.enableGui
      then [../../modules/home/gui.nix]
      else []
    );

  home.username = userSettings.username;
  home.homeDirectory = "/home/${userSettings.username}";
  home.stateVersion = "25.05";

  xdg.enable = true;
  programs.home-manager.enable = true;
}

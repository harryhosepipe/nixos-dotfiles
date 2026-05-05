{
  config,
  pkgs,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
in {
  home.packages = with pkgs; [
    bashInteractive
    zsh
    fish
    fzf
    oh-my-posh
  ];

  home.sessionVariables.FZF_SHARE = "${pkgs.fzf}/share/fzf";

  xdg.configFile = {
    "bash".source = createSymlink "${dotfiles}/bash";
    "zsh".source = createSymlink "${dotfiles}/zsh";
    "fish".source = createSymlink "${dotfiles}/fish";
    "oh-my-posh".source = createSymlink "${dotfiles}/oh-my-posh";
  };
}

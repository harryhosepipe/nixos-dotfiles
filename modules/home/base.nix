{
  config,
  pkgs,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  shellSettings = import ../../shells/settings.nix;
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
in {
  imports = [
    ./codex.nix
    ./gitnexus.nix
    ./context-mode.nix
  ];

  home.sessionPath = shellSettings.sessionPath;
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    _ZO_ECHO = "1";
    _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}/.cache:${config.home.homeDirectory}/.local/share/Trash:${config.home.homeDirectory}/dotfiles/config/codex";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/ansible_razer";
        identitiesOnly = true;
      };
      "razer" = {
        hostname = "192.168.3.9";
        identityFile = "~/.ssh/ansible_razer";
        identitiesOnly = true;
      };
      "nixvm" = {
        hostname = "192.168.122.131";
      };
    };
  };

  services.ssh-agent.enable = true;

  programs.gh = {
    enable = true;
    settings.git_protocol = "https";
  };

  home.file.".bashrc".source = createSymlink "${dotfiles}/bash/.bashrc";
  home.file.".bash_profile".source = createSymlink "${dotfiles}/bash/.bash_profile";
  home.file.".profile".source = createSymlink "${dotfiles}/profile/.profile";
  home.file.".zshenv".source = createSymlink "${dotfiles}/zsh/.zshenv";

  home.packages = with pkgs; [
    htop
    btop
    tree
    file
    which
    bat
    doppler
  ];
}

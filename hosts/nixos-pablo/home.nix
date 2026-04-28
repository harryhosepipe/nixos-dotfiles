{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles/config";
  shellSettings = import ../../shells/settings.nix;
  fzfShare = "${pkgs.fzf}/share/fzf";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = {
    bash = "bash";
    # Keep the Neovim Lua config easy to find in the usual ~/.config/nvim place.
    nvim = "nvim";
    qtile = "qtile";
    zsh = "zsh";
    fish = "fish";
    "oh-my-posh" = "oh-my-posh";
  };
in
{
  imports = [
    ../../modules/home/git.nix
    ../../modules/home/codex.nix
    ../../modules/home/neovim.nix
  ];

  home.username = "pablo";
  home.homeDirectory = "/home/pablo";
  home.stateVersion = "25.05";

  home.sessionPath = shellSettings.sessionPath;
  home.sessionVariables = {
    EDITOR = "nvim";
    FZF_SHARE = fzfShare;
    VISUAL = "nvim";
    _ZO_ECHO = "1";
    _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}/.cache:${config.home.homeDirectory}/.local/share/Trash:${config.home.homeDirectory}/dotfiles/config/codex";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/ansible_razer";
        identitiesOnly = true;
      };
    };
  };

  services.ssh-agent.enable = true;

  programs.gh = {
    enable = true;
    settings = {
      # Tell gh to create GitHub remotes with SSH so Git uses the SSH key
      # already selected in the ssh config above.
      git_protocol = "ssh";
    };
  };

  home.file.".bashrc".source = createSymlink "${dotfiles}/bash/.bashrc";
  home.file.".bash_profile".source = createSymlink "${dotfiles}/bash/.bash_profile";
  home.file.".profile".source = createSymlink "${dotfiles}/profile/.profile";
  home.file.".zshenv".source = createSymlink "${dotfiles}/zsh/.zshenv";

  xdg.configFile =
    builtins.mapAttrs (name: subpath: {
      source = createSymlink "${dotfiles}/${subpath}";
      recursive = true;
    }) configDirs;

  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
    doppler
    bat
    btop
    oh-my-posh
    fzf
    zoxide
  ];
}

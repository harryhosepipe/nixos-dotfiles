{
  config,
  pkgs,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  shellSettings = import ../../../shells/settings.nix;
  fzfShare = "${pkgs.fzf}/share/fzf";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = {
    bash = "bash";
    nvim = "nvim";
    zsh = "zsh";
    fish = "fish";
    "oh-my-posh" = "oh-my-posh";
  };
in {
  # Shared Home Manager profile for user-wide defaults.
  # Keep GUI session config and host-specific app choices in host/profile files.
  imports = [
    ../git.nix
    ../codex.nix
    ../neovim.nix
    ../dev.nix
    ../gitnexus.nix
    ../context-mode.nix
  ];

  home.username = userSettings.username;
  home.homeDirectory = "/home/${userSettings.username}";
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
    settings = {
      # Use HTTPS until the GitHub SSH key is restored on new machines.
      git_protocol = "https";
    };
  };

  home.file.".bashrc".source = createSymlink "${dotfiles}/bash/.bashrc";
  home.file.".bash_profile".source = createSymlink "${dotfiles}/bash/.bash_profile";
  home.file.".profile".source = createSymlink "${dotfiles}/profile/.profile";
  home.file.".zshenv".source = createSymlink "${dotfiles}/zsh/.zshenv";

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = createSymlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configDirs;

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

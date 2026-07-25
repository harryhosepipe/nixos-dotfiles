{ config
, inputs
, pkgs
, userSettings
, ...
}:
let
  draculaQbittorrentTheme = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/dracula/qbittorrent/9020f6eb457087270179beb86d45914d434adb6b/dracula.qbtheme";
    hash = "sha256-tEhfn07mE5t8d7v7ciBrYIvPp0jzTUkgXExLZeeXbTc=";
  };
  shellSettings = import ../../shells/settings.nix;
  localPackages = import ../../packages { inherit pkgs; };
  fzfShare = "${pkgs.fzf}/share/fzf";
in
{
  imports = [
    ../../modules/home/git.nix
    ../../modules/home/dotfiles.nix
    ../../modules/home/firefox.nix
    ../../modules/home/language-toolchain.nix
    ../../modules/home/tmux.nix
    ../../modules/home/agent-workspace.nix
    ../../modules/home/dev.nix
    ../../modules/home/hermes.nix
    inputs.handy.homeManagerModules.default
  ];

  home.username = userSettings.username;
  home.homeDirectory = "/home/${userSettings.username}";
  home.stateVersion = "25.05";

  home.sessionPath = shellSettings.sessionPath;
  home.sessionVariables = {
    EDITOR = "nvim";
    FZF_SHARE = fzfShare;
    HYPRCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "breeze_cursors";
    VISUAL = "nvim";
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "breeze_cursors";
    _ZO_ECHO = "1";
    _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}/.cache:${config.home.homeDirectory}/.local/share/Trash:${config.home.homeDirectory}/dotfiles/config/codex";
  };

  home.pointerCursor = {
    package = pkgs.kdePackages.breeze;
    name = "breeze_cursors";
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Tell GTK and portal-aware apps that this desktop prefers dark colors.
  # Electron apps such as WhatsApp often read this through xdg-desktop-portal.
  gtk = {
    enable = true;
    colorScheme = "dark";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
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
    };
  };

  services.ssh-agent.enable = true;
  services.handy.enable = true;

  xdg.configFile."qBittorrent/themes/dracula.qbtheme".source = draculaQbittorrentTheme;

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = userSettings.email;
      lock_timeout = 18000;
      pinentry = pkgs.pinentry-curses;
    };
  };

  dotfiles = {
    homeFiles = {
      ".bashrc" = "bash/.bashrc";
      ".bash_profile" = "bash/.bash_profile";
      ".profile" = "profile/.profile";
      ".zshenv" = "zsh/.zshenv";
    };

    configDirs = {
      bash = "bash";
      hypr = "hypr";
      kanata = "kanata";
      nvim = "nvim";
      qtile = "qtile";
      swaync = "swaync";
      tmux = "tmux";
      waybar = "waybar";
      zsh = "zsh";
      fish = "fish";
      "oh-my-posh" = "oh-my-posh";
      zed = "zed";
      ghostty = "ghostty";
      wezterm = "wezterm";
    };
  };

  home.packages = with pkgs; [
    nixpkgs-fmt
    doppler
    bat
    btop
    eza
    oh-my-posh
    fzf
    zoxide
    thunar
    chromium
    google-chrome
    qbittorrent
    obsidian
    signal-desktop
    whatsapp-electron
    pavucontrol
    pwvucontrol
    localPackages.paper-desktop
    figma-linux
    figma-agent
    zed-editor
    telegram-desktop
    libreoffice-qt
    inputs.herdr.packages.${pkgs.system}.default
    localPackages.nextcloud-client_4_0_4
    localPackages.dokploy-cli
    wtype
    mpv
    yt-dlp
  ];
}

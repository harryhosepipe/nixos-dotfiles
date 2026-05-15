{ config
, inputs
, pkgs
, userSettings
, ...
}:
let
  shellSettings = import ../../shells/settings.nix;
  localPackages = import ../../packages { inherit pkgs; };
  fzfShare = "${pkgs.fzf}/share/fzf";
in
{
  imports = [
    ../../modules/home/git.nix
    ../../modules/home/dotfiles.nix
    ../../modules/home/language-toolchain.nix
    ../../modules/home/agent-workspace.nix
    ../../modules/home/dev.nix
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

  programs.firefox = {
    enable = true;
    package = null;
    configPath = ".mozilla/firefox";

    profiles.default = {
      id = 0;
      isDefault = true;
      path = "ehs619jc.default";

      settings = {
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        # "browser.tabs.tabMinWidth" = 80;
        "browser.startup.page" = 1;
        "browser.sessionstore.resume_from_crash" = false;
        "browser.sessionstore.max_resumed_crashes" = 0;
        "browser.aboutwelcome.enabled" = false;
        "browser.startup.homepage_override.mstone" = "ignore";
        "startup.homepage_welcome_url" = "";
        "startup.homepage_welcome_url.additional" = "";
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "dom.disable_beforeunload" = true;
        "signon.rememberSignons" = false;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.globalprivacycontrol.functionality.enabled" = true;
        "privacy.globalprivacycontrol.pbmode.enabled" = true;
        "nimbus.rollouts.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.usage.uploadEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "app.shield.optoutstudies.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.first_run" = false;
        "browser.discovery.enabled" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.asrouter" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

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
      waybar = "waybar";
      zsh = "zsh";
      fish = "fish";
      "oh-my-posh" = "oh-my-posh";
      zed = "zed";
      wezterm = "wezterm";
    };
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "text/html" = "firefox.desktop";
      "application/xhtml+xml" = "firefox.desktop";
    };
  };

  home.packages = with pkgs; [
    nixpkgs-fmt
    doppler
    bat
    btop
    oh-my-posh
    fzf
    zoxide
    thunar
    chromium
    signal-desktop
    whatsapp-electron
    pavucontrol
    pwvucontrol
    figma-linux
    figma-agent
    zed-editor
    telegram-desktop
    localPackages.nextcloud-client_4_0_4
    localPackages.dokploy-cli
    wtype
    mpv
    yt-dlp
  ];
}

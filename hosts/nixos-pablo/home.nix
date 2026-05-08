{
  config,
  pkgs,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  shellSettings = import ../../shells/settings.nix;
  fzfShare = "${pkgs.fzf}/share/fzf";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
  nextcloud-client_4_0_4 = pkgs.nextcloud-client.overrideAttrs (oldAttrs: {
    version = "4.0.4";
    src = pkgs.fetchFromGitHub {
      owner = "nextcloud-releases";
      repo = "desktop";
      tag = "v4.0.4";
      hash = "sha256-BEjsIx0knmTj6kgM7fsJV5XN660cRe9DbYxeL7YHPRo=";
    };
  });
  dokploy-cli = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "dokploy-cli";
    version = "0.29.2";

    src = pkgs.fetchFromGitHub {
      owner = "Dokploy";
      repo = "cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-LH0d7L+xzr+A8QCn/yOpy9UKM4PI47RVZrR4WlZXT6A=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-RSq0VCHLg+umP7SXgvgaBfxXf0Fr6aaUfJksTH50zM0=";
    };

    nativeBuildInputs = with pkgs; [
      nodejs
      pnpm
      pnpmConfigHook
    ];

    buildPhase = ''
      runHook preBuild
      pnpm run build
      substituteInPlace dist/index.js \
        --replace-fail 'version: "0.3.0"' 'version: "${finalAttrs.version}"'
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/dokploy-cli" "$out/bin"
      cp -r dist package.json node_modules "$out/lib/dokploy-cli/"
      chmod +x "$out/lib/dokploy-cli/dist/index.js"
      ln -s "$out/lib/dokploy-cli/dist/index.js" "$out/bin/dokploy"
      runHook postInstall
    '';
  });

  configDirs = {
    bash = "bash";
    hypr = "hypr";
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
in {
  imports = [
    ../../modules/home/git.nix
    ../../modules/home/codex.nix
    ../../modules/home/language-servers.nix
    ../../modules/home/neovim.nix
    ../../modules/home/dev.nix
    ../../modules/home/gitnexus.nix
    ../../modules/home/context-mode.nix
    ../../modules/home/pi.nix
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
      # Use HTTPS until the GitHub SSH key is restored on new machines.
      git_protocol = "https";
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
    nixpkgs-fmt
    doppler
    bat
    btop
    oh-my-posh
    fzf
    zoxide
    thunar
    signal-desktop
    whatsapp-electron
    pavucontrol
    figma-linux
    figma-agent
    zed-editor
    telegram-desktop
    nextcloud-client_4_0_4
    dokploy-cli
  ];
}

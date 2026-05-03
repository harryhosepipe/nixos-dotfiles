{
  config,
  pkgs,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = {
    hypr = "hypr";
    qtile = "qtile";
    swaync = "swaync";
    waybar = "waybar";
  };
in {
  # Desktop GUI Home Manager profile.
  # Keep this optional so server-style hosts do not inherit session config.

  home.sessionVariables = {
    HYPRCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "breeze_cursors";
    XCURSOR_SIZE = "24";
    XCURSOR_THEME = "breeze_cursors";
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

      # userChrome = ''
      #   :root {
      #     --tab-min-height: 28px !important;
      #     --toolbarbutton-inner-padding: 6px !important;
      #     --toolbarbutton-outer-padding: 2px !important;
      #     --urlbar-min-height: 28px !important;
      #   }
      #
      #   #TabsToolbar,
      #   #tabbrowser-tabs {
      #     min-height: 30px !important;
      #   }
      #
      #   .tabbrowser-tab {
      #     min-width: 80px !important;
      #     max-width: 160px !important;
      #     min-height: 28px !important;
      #     max-height: 28px !important;
      #   }
      #
      #   .tab-background {
      #     min-height: 28px !important;
      #   }
      #
      #   .tab-content {
      #     padding: 0 8px !important;
      #   }
      #
      #   #nav-bar {
      #     min-height: 34px !important;
      #   }
      #
      #   #urlbar-container {
      #     --urlbar-container-height: 32px !important;
      #   }
      #
      #   #urlbar {
      #     --urlbar-height: 28px !important;
      #     min-height: 28px !important;
      #   }
      #
      #   #PersonalToolbar {
      #     min-height: 28px !important;
      #   }
      # '';
    };
  };

  xdg.configFile =
    builtins.mapAttrs
    (name: subpath: {
      source = createSymlink "${dotfiles}/${subpath}";
      recursive = true;
    })
    configDirs;

  home.packages = with pkgs; [
    thunar
    signal-desktop
    whatsapp-electron
    pavucontrol
    figma-linux
    figma-agent
  ];
}

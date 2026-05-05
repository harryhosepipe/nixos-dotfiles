{
  pkgs,
  pkgs-unstable,
  ...
}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    configPath = ".mozilla/firefox";

    profiles.default = {
      id = 0;
      isDefault = true;
      path = "ehs619jc.default";

      settings = {
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
        "browser.startup.page" = 1;
        "browser.sessionstore.resume_from_crash" = true;
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
      };
    };
  };

  home.packages = [
    pkgs.xfce.thunar
    pkgs.pavucontrol
    pkgs-unstable.bitwarden-desktop
    pkgs-unstable.signal-desktop
    pkgs-unstable.whatsapp-electron
    pkgs-unstable.figma-linux
    pkgs-unstable.figma-agent
  ];
}

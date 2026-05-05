{userSettings, ...}: {
  imports = [
    /etc/nixos/hardware-configuration.nix

    ../../modules/system/base.nix
    ../../modules/system/users.nix
    ../../modules/system/networking.nix
    ../../modules/system/server.nix
    ../../modules/system/gui.nix
  ];

  networking.hostName = userSettings.hostname;
  time.timeZone = userSettings.timezone;
  i18n.defaultLocale = userSettings.locale;
}

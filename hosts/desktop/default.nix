{userSettings, ...}: {
  imports =
    [
      /etc/nixos/hardware-configuration.nix

      ../../modules/system/base.nix
      ../../modules/system/users.nix
      ../../modules/system/networking.nix
      ../../modules/system/gui.nix

      ./nvidia.nix
      ./vfio.nix
    ]
    ++ (
      if userSettings.enableManifest
      then [../../modules/system/app-workloads/manifest.nix]
      else []
    );

  networking.hostName = userSettings.hostname;
  time.timeZone = userSettings.timezone;
  i18n.defaultLocale = userSettings.locale;
}

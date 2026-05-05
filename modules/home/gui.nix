{userSettings, ...}: {
  imports =
    (
      if userSettings.desktopEnvironment == "hyprland"
      then [./gui/hyprland.nix]
      else if userSettings.desktopEnvironment == "qtile"
      then [./gui/qtile.nix]
      else throw "Unknown desktopEnvironment: ${userSettings.desktopEnvironment}"
    )
    ++ (
      if userSettings.enableGuiApps
      then [./gui/apps.nix]
      else []
    );
}

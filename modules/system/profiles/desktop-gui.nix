{...}: {
  # Desktop GUI system profile.
  # Hosts that should stay headless can omit this profile.
  imports = [
    ../gui/hyprland-greetd.nix
  ];
}

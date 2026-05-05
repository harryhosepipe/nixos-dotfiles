{
  hostname = "nixos-pablo";

  username = "pablo";
  fullName = "Pablo";
  name = "Pablo";
  email = "pablo@renderbros.com";

  dotFiles = "nix-dot";

  shell = "zsh";
  neovimProfile = "full";
  desktopEnvironment = "hyprland";

  isDesktop = true;
  isLaptop = false;
  isServer = false;

  enableGui = true;
  enableGuiApps = true;
  enableManifest = true;
  passwordlessSudo = true;
  sshPasswordAuthentication = true;

  timezone = "Africa/Johannesburg";
  locale = "en_ZA.UTF-8";
}

{
  hostname = "laptop";

  username = "pablo";
  fullName = "Pablo";
  name = "Pablo";
  email = "pablo@renderbros.com";

  dotFiles = "nix-dot";

  shell = "zsh";
  neovimProfile = "full";
  desktopEnvironment = "hyprland";

  isDesktop = false;
  isLaptop = true;
  isServer = false;

  enableGui = true;
  enableGuiApps = true;
  enableManifest = true;
  passwordlessSudo = true;
  sshPasswordAuthentication = true;

  timezone = "Africa/Johannesburg";
  locale = "en_ZA.UTF-8";
}

{
  hostname = "server";

  username = "pablo";
  fullName = "Pablo";
  name = "Pablo";
  email = "pablo@renderbros.com";

  dotFiles = "nix-dot";

  shell = "bash";
  neovimProfile = "lite";
  desktopEnvironment = "qtile";

  isDesktop = false;
  isLaptop = false;
  isServer = true;

  enableGui = true;
  enableGuiApps = false;
  enableManifest = false;
  passwordlessSudo = false;
  sshPasswordAuthentication = false;

  timezone = "Africa/Johannesburg";
  locale = "en_ZA.UTF-8";
}

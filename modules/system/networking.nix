{userSettings, ...}: {
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [22];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = userSettings.sshPasswordAuthentication;
      PermitRootLogin = "no";
    };
  };
}

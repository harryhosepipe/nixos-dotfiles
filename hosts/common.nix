{
  pkgs,
  userSettings,
  ...
}:
let
  shellSettings = import ../shells/settings.nix;
  shellPackages = {
    bash = pkgs.bashInteractive;
    zsh = pkgs.zsh;
    fish = pkgs.fish;
  };
in
{
  # This file is the shared system base.
  # Put settings here when they should be true for every machine.

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  time.timeZone = "Africa/Johannesburg";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  security.polkit.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tailscale = {
    enable = true;

    # Opens Tailscale's UDP port in the firewall.
    # This helps direct connections work better.
    openFirewall = true;
  };

  # Let this named user use sudo without a password prompt.
  # This keeps the rule easy to find next to the shared user account.
  security.sudo.extraRules = [
    {
      users = [ userSettings.username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  users.users.${userSettings.username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = shellPackages.${shellSettings.defaultShell};
    packages = with pkgs; [
      tree
    ];
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.firefox = {
    enable = true;
    policies = {
      DisableRemoteImprovements = true;
    };
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    alacritty
    wezterm
    git
    gvfs
    tumbler
    thunar-volman
    ripgrep
  ];

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.inconsolata
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

{ pkgs
, userSettings
, ...
}:
let
  shellSettings = import ../shells/settings.nix;
  tx-02 = pkgs.stdenvNoCC.mkDerivation {
    pname = "tx-02";
    version = "local";
    src = ../fonts/TX-02;

    installPhase = ''
      runHook preInstall
      install -Dm644 *.otf -t $out/share/fonts/opentype/TX-02
      runHook postInstall
    '';
  };
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
  boot.kernelModules = [ "uinput" ];

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
      "input"
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
    ghostty
    wezterm
    git
    gvfs
    tumbler
    thunar-volman
    ripgrep
    ydotool
  ];

  systemd.services.ydotoold = {
    description = "ydotool input daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.ydotool}/bin/ydotoold";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  fonts.packages = with pkgs; [
    tx-02
    nerd-fonts.inconsolata
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}

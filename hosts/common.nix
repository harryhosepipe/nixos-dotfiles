{ config, lib, pkgs, ... }:

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

  services.displayManager.ly.enable = true;
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  users.users.pablo = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = shellPackages.${shellSettings.defaultShell};
    packages = with pkgs; [
      tree
    ];
  };

  programs.zsh.enable = true;
  programs.fish.enable = true;
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    alacritty
    git
  ];

  environment.shells = with pkgs; [
    bashInteractive
    zsh
    fish
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.inconsolata
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}

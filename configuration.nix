{ config, lib, pkgs, ... }:

let
  shellSettings = import ./shells/settings.nix;
  shellPackages = {
    bash = pkgs.bashInteractive;
    zsh = pkgs.zsh;
    fish = pkgs.fish;
  };
in

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-btw";
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
    nerd-fonts.jetbrains-mono
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";

}

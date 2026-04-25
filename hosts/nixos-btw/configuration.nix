{ ... }:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
  ];

  # This file is the machine's own room.
  # Put settings here when they only make sense on this host.
  networking.hostName = "nixos-btw";

  system.stateVersion = "25.05";
}

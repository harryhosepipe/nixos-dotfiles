{ host, ... }:

{
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ../../modules/system/gui/qtile-ly.nix
  ];

  # This file is the machine's own room.
  # The real machine name comes from hosts.nix so you can rename it in one place.
  networking.hostName = host.hostName;

  system.stateVersion = "25.05";
}

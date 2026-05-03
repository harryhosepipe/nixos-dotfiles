{host, ...}: {
  imports = [
    ../../modules/system/profiles/shared-base.nix
    ../../modules/system/profiles/desktop-gui.nix
    ./hardware-configuration.nix
    ./nvidia.nix
    ./vfio.nix
    ../../modules/system/app-workloads/manifest.nix
  ];

  # This file is the machine's own room.
  # The real machine name comes from hosts.nix so you can rename it in one place.
  networking.hostName = host.hostName;

  system.stateVersion = "25.05";
}

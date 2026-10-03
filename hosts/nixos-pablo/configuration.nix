{host, ...}: {
  imports = [
    ../common.nix
    ./hardware-configuration.nix
    ./kanata.nix
    ./unfree.nix
    ./nvidia.nix
    ../../modules/system/docker/manifest.nix
    ../../modules/system/docker/penpot.nix
    ../../modules/system/gui/hyprland-greetd.nix
    ../../modules/system/vfio/single-gpu-passthrough.nix
  ];

  # This file is the machine's own room.
  # The real machine name comes from hosts.nix so you can rename it in one place.
  networking.hostName = host.hostName;
  networking.networkmanager.dns = "none";
  networking.nameservers = ["192.168.88.247"];
  services.tailscale.extraSetFlags = ["--accept-dns=false"];
  users.users.pablo.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5hBuvy7gqjDvkeyZLWUpk8FH9gTKJeC/2jOlmAdoeE pablo@renderbros.com"
  ];

  services.flatpak = {
    enable = true;
    packages = ["info.beyondallreason.bar"];
    update.auto.enable = true;
  };

  passthrough.singleGpu = {
    enable = true;
    vmNames = [
      "win10-pab"
      "win10-game"
    ];
    cpuVendor = "amd";
    gpu.videoPci = "0000:09:00.0";
    gpu.audioPci = "0000:09:00.1";
    usbControllerPci = "0000:0b:00.3";
    sharedDir = "/srv/vm-shares/win10-pab-projects";
  };

  system.stateVersion = "25.05";
}

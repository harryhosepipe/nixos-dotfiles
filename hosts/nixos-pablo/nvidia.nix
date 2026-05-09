{ config, lib, ... }:

{
  # This machine has an NVIDIA graphics card.
  services.xserver.videoDrivers = [ "nvidia" ];

  # Allow only the unfree NVIDIA packages required by this host's driver setup.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-settings"
      "nvidia-x11"
    ];

  hardware.graphics.enable = true;

  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}

{...}: {
  imports = [
    ../../modules/system/vfio/single-gpu-passthrough.nix
  ];

  # Desktop-only single-GPU passthrough.
  # Keep PCI IDs, VM names, and hooks tied to this physical machine.
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
}

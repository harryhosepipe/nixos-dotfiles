{ lib, ... }:

{
  # Allow only the unfree packages this host explicitly uses.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "google-chrome"
      "nvidia-settings"
      "nvidia-x11"
      "nvim-highlight-colors"
      "obsidian"
    ];
}

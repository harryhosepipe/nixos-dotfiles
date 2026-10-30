{ lib, ... }:

{
  # Allow only the unfree packages this host explicitly uses.
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "claude-code"
      "figma-desktop"
      "google-chrome"
      "michelangelus"
      "nvidia-settings"
      "nvidia-x11"
      "nvim-highlight-colors"
      "obsidian"
      "oma-cast"
      "paper-desktop"
      "strata"
      "tradingview"
    ];
}

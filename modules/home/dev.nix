{pkgs, ...}: {
  # This file is for everyday developer tools.
  # Keep project-specific versions in each project when possible.

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    bun
    nodejs
    pnpm
    jq
    just
    curl
    unzip
    python3
    gnumake
    gcc
    pkg-config
    tree-sitter
  ];
}

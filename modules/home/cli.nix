{pkgs, ...}: {
  imports = [
    ./dev.nix
  ];

  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    bat
    fzf
    jq
    yq
    zoxide
    direnv
    nil
    nixpkgs-fmt
  ];

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zoxide.enable = true;
}

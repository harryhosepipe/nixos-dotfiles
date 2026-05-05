pkgs: let
  nix = with pkgs; [
    nil
    nixd
    alejandra
  ];
in {
  inherit nix;

  all = nix;
}

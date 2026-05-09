pkgs: let
  nix = with pkgs; [
    nil
    nixd
    alejandra
  ];
  packageMetadata = with pkgs; [
    package-version-server
  ];
in {
  inherit nix packageMetadata;

  all = nix ++ packageMetadata;
}

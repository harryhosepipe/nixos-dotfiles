pkgs: let
  nix = with pkgs; [
    nil
    nixd
    alejandra
  ];
  lua = with pkgs; [
    lua-language-server
  ];
  web = with pkgs; [
    svelte-language-server
    astro-language-server
  ];
  packageMetadata = with pkgs; [
    package-version-server
  ];
in {
  inherit nix lua web packageMetadata;

  all = nix ++ lua ++ web ++ packageMetadata;
}

pkgs: let
  nix = with pkgs; [
    nil
    nixd
    alejandra
  ];
  lua = with pkgs; [
    lua-language-server
    stylua
  ];
  web = with pkgs; [
    svelte-language-server
    astro-language-server
    typescript
    vscode-langservers-extracted
    tailwindcss-language-server
    emmet-language-server
    eslint
    prettier
  ];
  packageMetadata = with pkgs; [
    package-version-server
  ];
in {
  inherit nix lua web packageMetadata;

  all = nix ++ lua ++ web ++ packageMetadata;
}

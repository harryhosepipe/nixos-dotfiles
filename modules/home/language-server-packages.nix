pkgs: let
  cssVariablesLanguageServerBin = pkgs.runCommand "css-variables-language-server-bin" {} ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.css-variables-language-server}/bin/css-variables-language-server "$out/bin/"
  '';
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
    (lib.hiPrio vscode-css-languageserver)
    vscode-langservers-extracted
    cssVariablesLanguageServerBin
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

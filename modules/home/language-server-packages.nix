pkgs: let
  cssVariablesLanguageServerBin = pkgs.runCommand "css-variables-language-server-bin" {} ''
    mkdir -p "$out/bin"
    ln -s ${pkgs.css-variables-language-server}/bin/css-variables-language-server "$out/bin/"
  '';
  vscodeLangserversCommonJs = pkgs.vscode-langservers-extracted.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        server="$out/lib/node_modules/vscode-langservers-extracted/lib/json-language-server/node"
        echo '{ "type": "commonjs" }' > "$server/package.json"
        substituteInPlace "$server/jsonServerMain.js" \
          --replace-fail 'import.meta.url' 'require("url").pathToFileURL(__filename)'
      '';
  });
  jsonLanguageServerNode22 = pkgs.writeShellScriptBin "vscode-json-language-server" ''
    exec ${pkgs.nodejs_22}/bin/node \
      ${vscodeLangserversCommonJs}/lib/node_modules/vscode-langservers-extracted/bin/vscode-json-language-server \
      "$@"
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
    (lib.hiPrio jsonLanguageServerNode22)
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

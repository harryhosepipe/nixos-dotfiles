{pkgs, ...}: let
  contextModeVersion = "1.0.103";

  context-mode = pkgs.writeShellScriptBin "context-mode" ''
    export PATH=${pkgs.nodejs_22}/bin:$PATH
    exec ${pkgs.nodejs_22}/bin/npx -y context-mode@${contextModeVersion} "$@"
  '';
in {
  # Context Mode is an npm MCP server.
  # Node 22 is used here because it starts cleanly on this NixOS setup.
  home.packages = [
    context-mode
  ];
}

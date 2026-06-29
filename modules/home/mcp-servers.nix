{pkgs, ...}: let
  npmMcpServer = {
    name,
    package,
    version,
    node ? pkgs.nodejs_22,
    runtimeTools ? [],
  }:
    pkgs.writeShellScriptBin name ''
      export PATH=${pkgs.lib.makeBinPath ([node] ++ runtimeTools)}:$PATH
      exec ${node}/bin/npx -y ${package}@${version} "$@"
    '';
in {
  # MCP servers shared by coding agents such as Codex and Pi.
  home.packages = [
    (npmMcpServer {
      name = "context-mode";
      package = "context-mode";
      version = "1.0.168";
      runtimeTools = with pkgs; [
        bashInteractive
        coreutils
        findutils
        git
        gnugrep
        gnused
        ripgrep
      ];
    })

    (npmMcpServer {
      name = "gitnexus";
      package = "gitnexus";
      version = "1.6.3";
      node = pkgs.nodejs;
    })
  ];
}

{ pkgs, ... }:

let
  npmMcpServer =
    {
      name,
      package,
      version,
      node ? pkgs.nodejs_22,
    }:
    pkgs.writeShellScriptBin name ''
      export PATH=${node}/bin:$PATH
      exec ${node}/bin/npx -y ${package}@${version} "$@"
    '';
in
{
  # MCP servers shared by coding agents such as Codex and Pi.
  home.packages = [
    (npmMcpServer {
      name = "context-mode";
      package = "context-mode";
      version = "1.0.111";
    })

    (npmMcpServer {
      name = "gitnexus";
      package = "gitnexus";
      version = "1.6.3";
      node = pkgs.nodejs;
    })
  ];
}

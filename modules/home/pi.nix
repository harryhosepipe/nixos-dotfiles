{ config, pkgs, userSettings, ... }:
let
  piVersion = "0.73.0";
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  pi = pkgs.writeShellScriptBin "pi" ''
    export PATH=${pkgs.nodejs_22}/bin:$PATH
    exec ${pkgs.nodejs_22}/bin/npx -y @mariozechner/pi-coding-agent@${piVersion} "$@"
  '';
in
{
  # Pi is an npm coding-agent CLI.
  # Nix provides Node and the command wrapper; Pi owns ~/.pi at runtime.
  home.packages = [
    pi
  ];

  # Local Pi resources. These stay out-of-store so extension TypeScript and
  # npm dependencies can be edited/installed without rebuilding the system.
  home.file.".pi/agent/AGENTS.md".source = createSymlink "${dotfiles}/pi/AGENTS.md";
  home.file.".pi/agent/mcp.json".source = createSymlink "${dotfiles}/pi/mcp.json";
  home.file.".pi/agent/extensions/mcp-bridge".source = createSymlink "${dotfiles}/pi/extensions/mcp-bridge";
}

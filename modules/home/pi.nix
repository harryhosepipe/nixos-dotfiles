{ config, pkgs, userSettings, ... }:
let
  piVersion = "0.73.0";

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
  dotfiles.homeFiles = {
    ".pi/agent/AGENTS.md" = "pi/AGENTS.md";
    ".pi/agent/mcp.json" = "pi/mcp.json";
    ".pi/agent/extensions/mcp-bridge" = "pi/extensions/mcp-bridge";
  };
}

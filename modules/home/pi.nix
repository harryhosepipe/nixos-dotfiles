{ pkgs, ... }:
let
  piVersion = "0.82.1";

  pi = pkgs.writeShellScriptBin "pi" ''
    export PATH=${pkgs.nodejs_22}/bin:$PATH
    unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR PI_PACKAGE_DIR
    exec ${pkgs.nodejs_22}/bin/npx --prefer-offline -y @earendil-works/pi-coding-agent@${piVersion} "$@"
  '';
in
{
  home.packages = [
    pi
  ];

  # Keep editable declarative resources in the dotfiles repo while Pi owns
  # credentials, settings, sessions, and other runtime state in ~/.pi/agent.
  dotfiles.homeFiles = {
    ".pi/agent/AGENTS.md" = "pi/AGENTS.md";
    ".pi/agent/mcp.json" = "pi/mcp.json";
    ".pi/agent/extensions/mcp-bridge" = "pi/extensions/mcp-bridge";
  };
}

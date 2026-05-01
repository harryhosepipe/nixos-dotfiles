{ pkgs, ... }:

let
  gitnexusVersion = "1.6.3";

  gitnexus = pkgs.writeShellScriptBin "gitnexus" ''
    exec ${pkgs.nodejs}/bin/npx -y gitnexus@${gitnexusVersion} "$@"
  '';
in
{
  # GitNexus is an npm tool, so this wrapper keeps the command name simple.
  # Nix provides Node here; npx downloads the pinned GitNexus version when used.
  home.packages = [
    gitnexus
  ];
}

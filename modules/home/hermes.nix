{ inputs
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermesDesktop = inputs.hermes-agent.packages.${system}.desktop;
in
{
  home.packages = [
    hermesDesktop
  ];

  xdg.desktopEntries.hermes-desktop = {
    name = "Hermes Desktop";
    exec = "${hermesDesktop}/bin/hermes-desktop";
    terminal = false;
    categories = [ "Utility" ];
  };
}

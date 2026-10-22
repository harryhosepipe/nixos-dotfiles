{ pkgs, ... }:
let
  omaCast = import ../../packages/oma-cast.nix { inherit pkgs; };
in
{
  home.packages = [ omaCast ];
  fonts.fontconfig.enable = true;

  systemd.user.services.oma-cast = {
    Unit = {
      Description = "Oma Cast application launcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      # Electron selects its display backend from the launcher's environment.
      # greetd does not reliably import the session type into the user manager.
      Environment = [ "XDG_SESSION_TYPE=wayland" "NIXOS_OZONE_WL=1" ];
      ExecStart = "${omaCast}/bin/oma-cast daemon";
      Restart = "on-failure";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.desktopEntries.oma-cast = {
    name = "Oma Cast";
    comment = "Search applications and commands";
    exec = "${omaCast}/bin/oma-cast show";
    icon = "system-search";
    terminal = false;
    categories = [ "Utility" ];
  };
}

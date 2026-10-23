{ pkgs, ... }: {
  home.packages = [ (pkgs.callPackage ../../packages/dns-switcher.nix { }) ];
}

{pkgs, ...}: let
  languageServers = import ./language-server-packages.nix pkgs;
in {
  # Shared language server tools for editors and terminals.
  home.packages = languageServers.all;
}

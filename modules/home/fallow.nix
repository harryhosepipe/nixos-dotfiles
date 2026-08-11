{ pkgs, ... }:
let
  localPackages = import ../../packages { inherit pkgs; };
in
{
  home.packages = [
    localPackages.fallow
  ];
}

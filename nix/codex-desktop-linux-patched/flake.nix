{
  description = "Patched codex-desktop-linux flake";

  inputs = {
    upstream.url = "github:ilysenko/codex-desktop-linux";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs @ {
    upstream,
    nixpkgs,
    flake-utils,
    ...
  }: let
    upstreamFlake = import "${upstream}/flake.nix";
    patchedOutputs =
      upstreamFlake.outputs {
        self =
          patchedOutputs
          // {
            rev = upstream.rev or "";
            dirtyRev = upstream.dirtyRev or "";
            lastModified = upstream.lastModified or 1;
          };
        inherit nixpkgs flake-utils;
      };
  in
    patchedOutputs;
}

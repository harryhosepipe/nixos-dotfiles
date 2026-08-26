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
    upstreamOutputs =
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

    # OpenAI's official Linux package uses browser_crashpad_handler, while the
    # upstream Nix derivation currently patches only chrome_crashpad_handler.
    patchPackage = system: package:
      package.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ nixpkgs.legacyPackages.${system}.patchelf ];
        postInstall = (old.postInstall or "") + ''
          crashpad="$out/opt/codex-desktop/browser_crashpad_handler"
          if [ -f "$crashpad" ]; then
            patchelf \
              --set-interpreter "$(cat ${nixpkgs.legacyPackages.${system}.stdenv.cc}/nix-support/dynamic-linker)" \
              "$crashpad"
          fi
        '';
      });

    patchedOutputs = upstreamOutputs // {
      packages = builtins.mapAttrs
        (system: packages: builtins.mapAttrs (_: patchPackage system) packages)
        upstreamOutputs.packages;
    };
  in
    patchedOutputs;
}

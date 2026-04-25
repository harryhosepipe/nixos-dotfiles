{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  codex = pkgs.stdenvNoCC.mkDerivation {
    pname = "codex";
    version = "0.123.0";

    src = pkgs.fetchurl {
      url =
        "https://github.com/openai/codex/releases/download/rust-v0.123.0/codex-x86_64-unknown-linux-musl.tar.gz";
      sha256 = "sha256-SxJ/o89pRDxtLmiBqIMBi2c3tIi5nQHYEuOGKPV90sY=";
    };

    sourceRoot = ".";

    installPhase = ''
      install -Dm755 codex-x86_64-unknown-linux-musl $out/bin/codex
    '';
  };
in
{
  home.packages = [
    codex
  ];

  home.sessionVariables = {
    CODEX_HOME = "${config.xdg.configHome}/codex";
  };

  xdg.configFile."codex/config.toml".source =
    createSymlink "${dotfiles}/codex/config.toml";
}

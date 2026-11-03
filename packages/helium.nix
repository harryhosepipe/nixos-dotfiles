{ pkgs }:
let
  pname = "helium";
  version = "0.20.2.1";
  src = pkgs.fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-rEkoQk0xyGP/86t1076HPfyS7eAOaIljTcvFiBoSA5c=";
  };
  contents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };
in
pkgs.appimageTools.wrapAppImage {
  inherit pname version;
  src = contents;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  extraPkgs = pkgs: [
    pkgs.alsa-lib
    pkgs.libva
    pkgs.pipewire
  ];

  extraInstallCommands = ''
    # Use native Wayland for terminal launches and every desktop action.
    wrapProgram $out/bin/helium --add-flags "--ozone-platform=wayland"

    install -Dm444 ${contents}/helium.desktop \
      $out/share/applications/helium.desktop
    substituteInPlace $out/share/applications/helium.desktop \
      --replace-fail 'Exec=helium' "Exec=$out/bin/helium"
    install -Dm444 ${contents}/helium.png \
      $out/share/icons/hicolor/256x256/apps/helium.png
  '';

  meta = {
    description = "Private, fast, and honest web browser based on Chromium";
    homepage = "https://helium.computer";
    license = pkgs.lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
  };
}

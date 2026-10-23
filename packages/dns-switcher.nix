{ lib, stdenvNoCC, python3, gtk4, gobject-introspection, wrapGAppsHook4, makeWrapper }:
let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "dns-switcher";
  version = "1.0.0";
  src = ../config/dns-switcher;
  nativeBuildInputs = [ wrapGAppsHook4 makeWrapper gobject-introspection ];
  buildInputs = [ gtk4 ];
  dontBuild = true;
  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/dns-switcher $out/bin $out/share/applications
    cp app.py backend.py style.css $out/share/dns-switcher/
    cat > $out/share/applications/io.github.nixdot.DNSSwitcher.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=DNS Switcher
    Comment=Switch between Pi-hole and a fallback DNS service
    Exec=$out/bin/dns-switcher
    Icon=network-wired-symbolic
    Terminal=false
    Categories=Network;Settings;
    StartupWMClass=io.github.nixdot.DNSSwitcher
    EOF
    runHook postInstall
  '';

  preFixup = ''
    makeWrapper ${python}/bin/python3 $out/bin/dns-switcher \
      --add-flags "$out/share/dns-switcher/app.py" \
      --set GDK_BACKEND wayland \
      --set PYTHONDONTWRITEBYTECODE 1 \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "A native Wayland DNS rescue panel for openresolv";
    platforms = lib.platforms.linux;
    mainProgram = "dns-switcher";
  };
}

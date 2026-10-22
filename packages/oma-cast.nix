{ pkgs }:
let
  omarchy = pkgs.fetchFromGitHub {
    owner = "omacom";
    repo = "omarchy";
    rev = "3ac43659dcbf88e84d951e3ce979b48a60a7d1f2";
    hash = "sha256-CExCznE35nGHg+PCEdWkyRK9m/SVBM6Pjj/sSRTxOIQ=";
  };
  pasteAnswer = pkgs.writeShellScript "oma-cast-paste-answer" ''
    set -euo pipefail
    printf '%s' "$1" | ${pkgs.wl-clipboard}/bin/wl-copy
    # Wait for the launcher to close before typing into the focused window.
    ${pkgs.coreutils}/bin/sleep 0.15
    ${pkgs.wtype}/bin/wtype -- "$1"
  '';
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "oma-cast";
  version = "0.0.1-unstable-2026-10-21";

  src = pkgs.fetchFromGitHub {
    owner = "typecraft-dev";
    repo = "oma-cast";
    rev = "c6013b8d91a5fbb9f8b375c0cb48125d232571ec";
    hash = "sha256-XzlwA2K6btLRtG2SrskmbfTyCMWtKlzSYv8mHPIFBvQ=";
  };

  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontBuild = true;

  # Host only the launcher, with Omarchy's shared UI components. Apps use
  # Quickshell's desktop-entry execution; web searches use the default browser.
  postPatch = ''
    substituteInPlace plugin/Backend.qml \
      --replace-fail \
        'else Util.execArgv(["uwsm-app", "--", "gtk-launch", candidate.appId + ".desktop"])' \
        'else { var entry = DesktopEntries.byId(candidate.appId); if (!entry) throw new Error("Application no longer installed"); entry.execute() }' \
      --replace-fail '"omarchy-launch-browser"' '"xdg-open"' \
      --replace-fail '"omarchy-clipboard-paste-text"' '"${pasteAnswer}"' \
      --replace-fail \
        'for (var b = 0; b < RootSearch.BUILTINS.length; b++) next.push(RootSearch.builtinCandidate(RootSearch.BUILTINS[b]))' \
        'for (var b = 0; b < RootSearch.BUILTINS.length; b++) if (RootSearch.BUILTINS[b].id !== "builtin:omarchy-menu") next.push(RootSearch.builtinCandidate(RootSearch.BUILTINS[b]))'
  '';

  installPhase = ''
    runHook preInstall
    shellDir="$out/share/oma-cast"
    mkdir -p "$shellDir/Commons" "$shellDir/Ui" "$out/libexec"
    cp -r plugin "$shellDir/plugin"
    install -m444 ${../config/oma-cast/shell.qml} "$shellDir/shell.qml"

    for file in Border.qml BorderGeometry.js Color.qml I18n.qml IpcRegistry.qml \
      Numbers.js Plural.js ShellIpc.qml Style.qml Util.qml; do
      install -m444 "${omarchy}/shell/Commons/$file" "$shellDir/Commons/$file"
    done
    cat > "$shellDir/Commons/qmldir" <<'EOF'
    module qs.Commons
    singleton Border 1.0 Border.qml
    singleton Color 1.0 Color.qml
    singleton I18n 1.0 I18n.qml
    singleton IpcRegistry 1.0 IpcRegistry.qml
    singleton Style 1.0 Style.qml
    singleton Util 1.0 Util.qml
    ShellIpc 1.0 ShellIpc.qml
    EOF

    for file in BorderOverlay BorderSurface OverlayWindow PointerMoveGate; do
      install -m444 "${omarchy}/shell/Ui/$file.qml" "$shellDir/Ui/$file.qml"
    done
    cat > "$shellDir/Ui/qmldir" <<'EOF'
    module qs.Ui
    BorderOverlay 1.0 BorderOverlay.qml
    BorderSurface 1.0 BorderSurface.qml
    OverlayWindow 1.0 OverlayWindow.qml
    PointerMoveGate 1.0 PointerMoveGate.qml
    EOF

    # Keep Omarchy's action catalog empty: its commands target a different OS.
    mkdir -p "$shellDir/default/omarchy" "$shellDir/default/i18n/en"
    echo '{}' > "$shellDir/default/omarchy/omarchy-menu.jsonc"
    install -m444 ${omarchy}/default/i18n/en/shell.json "$shellDir/default/i18n/en/shell.json"
    install -m444 ${omarchy}/default/i18n/locales.json "$shellDir/default/i18n/locales.json"
    install -Dm444 ${omarchy}/default/fonts/omarchy/omarchy.ttf \
      "$out/share/fonts/truetype/omarchy.ttf"

    install -m444 ${../config/oma-cast/oma-cast.sh} "$out/libexec/oma-cast"
    makeWrapper ${pkgs.bash}/bin/bash "$out/bin/oma-cast" \
      --add-flags "$out/libexec/oma-cast" \
      --set OMA_CAST_SHELL "$shellDir" \
      --set OMA_CAST_QUICKSHELL ${pkgs.quickshell}/bin/quickshell \
      --set OMARCHY_PATH "$shellDir" \
      --set OMARCHY_MENU_FONT "Inconsolata Nerd Font" \
      --set QT_QPA_PLATFORM wayland \
      --prefix PATH : ${pkgs.lib.makeBinPath (with pkgs; [ bash coreutils fontconfig hyprland systemd wl-clipboard xdg-utils ])}
    runHook postInstall
  '';

  meta = {
    description = "Raycast-style launcher with a standalone NixOS host";
    homepage = "https://github.com/typecraft-dev/oma-cast";
    # Upstream currently does not provide a license.
    license = pkgs.lib.licenses.unfree;
    platforms = pkgs.lib.platforms.linux;
    mainProgram = "oma-cast";
  };
}

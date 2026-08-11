{ pkgs }:
let
  buzzVersion = "0.5.8";
  buzzSrc = pkgs.fetchurl {
    url = "https://github.com/block/buzz/releases/download/desktop-v${buzzVersion}/Buzz_${buzzVersion}_amd64.AppImage";
    hash = "sha256-VVWoJA8cyipv9BtCwme+GjcP/kKN1Lt+1wL3AU4SHYs=";
  };
  # Tauri's opener resolves xdg-open inside the AppImage FHS. Delegate that
  # call to NixOS's host opener, where the desktop MIME associations and the
  # user's browser are available.
  buzzBrowserLauncher = pkgs.writeShellScriptBin "xdg-open" ''
    runtimeDir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export XDG_RUNTIME_DIR="$runtimeDir"
    export DBUS_SESSION_BUS_ADDRESS="''${DBUS_SESSION_BUS_ADDRESS:-unix:path=$runtimeDir/bus}"
    export PATH="/etc/profiles/per-user/''${USER:-$(id -un)}/bin:/run/current-system/sw/bin:$PATH"
    exec /run/current-system/sw/bin/xdg-open "$@"
  '';
  buzzContents = pkgs.appimageTools.extractType2 {
    pname = "buzz";
    version = buzzVersion;
    src = buzzSrc;
    postExtract = ''
      substituteInPlace $out/apprun-hooks/linuxdeploy-plugin-gtk.sh \
        --replace-fail 'export GDK_BACKEND=x11' 'export GDK_BACKEND=wayland'
      install -Dm755 ${buzzBrowserLauncher}/bin/xdg-open $out/usr/bin/xdg-open
    '';
  };
  codexAcpVersion = "1.1.14";
  codexAcp = pkgs.buildNpmPackage {
    pname = "codex-acp";
    version = codexAcpVersion;
    src = ../nix/codex-acp-npm;
    npmDepsHash = "sha256-0RuBcLWnWWvCiyPtEMWNMyCDl2SVKiubFVaVNnBgh8U=";
    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/bin" "$out/lib/node_modules"
      cp -r node_modules/. "$out/lib/node_modules/"
      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/codex-acp" \
        --run 'if [ -z "''${CODEX_PATH:-}" ] && command -v codex >/dev/null 2>&1; then export CODEX_PATH="$(command -v codex)"; fi' \
        --add-flags "$out/lib/node_modules/@agentclientprotocol/codex-acp/dist/index.js"
      runHook postInstall
    '';

    meta = {
      description = "Codex adapter for the Agent Client Protocol";
      homepage = "https://github.com/agentclientprotocol/codex-acp";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "codex-acp";
    };
  };
  buzzTerminalLauncher = pkgs.writeShellScriptBin "x-terminal-emulator" ''
    exec ${pkgs.ghostty}/bin/ghostty "$@"
  '';
  # Buzz's GUI readiness probe can report logged out even when codex-acp can
  # initialize with the existing credentials. Keep the workaround scoped to
  # Buzz's FHS environment and delegate every non-status command to the real
  # Home Manager Codex CLI.
  buzzCodexProbeShim = pkgs.writeShellScriptBin "codex" ''
    codexHome="''${CODEX_HOME:-$HOME/.codex}"
    if [ "$#" -eq 2 ] && [ "$1" = login ] && [ "$2" = status ] \
      && [ -s "$codexHome/auth.json" ]; then
      echo "Logged in using ChatGPT"
      exit 0
    fi

    codexProfile="/etc/profiles/per-user/''${USER:-$(id -un)}/bin/codex"
    if [ ! -x "$codexProfile" ]; then
      echo "Buzz: Codex CLI is missing at $codexProfile" >&2
      exit 127
    fi
    exec "$codexProfile" "$@"
  '';
  figmaDesktopVersion = "126.5.6";
  figmaDesktopSrc = pkgs.fetchurl {
    url = "https://github.com/IliyaBrook/figma-linux/releases/download/${figmaDesktopVersion}/figma-desktop-${figmaDesktopVersion}-amd64.AppImage";
    hash = "sha256-SLn4y+NVCcBDZrGqIpmpIEQavY7xngt5JMI8yG1g6/0=";
  };
  figmaDesktopContents = pkgs.appimageTools.extractType2 {
    pname = "figma-desktop";
    version = figmaDesktopVersion;
    src = figmaDesktopSrc;
  };
  paperDesktopVersion = "0.5.0";
  paperDesktopSrc = pkgs.fetchurl {
    url = "https://download.paper.design/linux/appImage";
    hash = "sha256-1Ezg5+5AgotZCa7meMqYdPf6UP/hJxlm5AONbx1OZWE=";
  };
  paperDesktopContents = pkgs.appimageTools.extractType2 {
    pname = "paper-desktop";
    version = paperDesktopVersion;
    src = paperDesktopSrc;
  };
  t3codeVersion = "0.0.33";
  t3codeSrc = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${t3codeVersion}/T3-Code-${t3codeVersion}-x86_64.AppImage";
    hash = "sha256-QVyGSPQ8PSLVcvJ/LFD9yMMQ6n/N6VN7kD4eLxyHdaE=";
  };
  t3codeContents = pkgs.appimageTools.extractType2 {
    pname = "t3code";
    version = t3codeVersion;
    src = t3codeSrc;
  };
in
{
  buzz = pkgs.appimageTools.wrapAppImage {
    pname = "buzz";
    version = buzzVersion;
    src = buzzContents;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    extraPkgs = pkgs: [
      codexAcp
      buzzCodexProbeShim
      buzzTerminalLauncher
      pkgs.elfutils
      pkgs.zstd
      pkgs.gst_all_1.gstreamer
      pkgs.gst_all_1.gst-plugins-base
      pkgs.gst_all_1.gst-plugins-good
      pkgs.gst_all_1.gst-plugins-bad
      pkgs.gst_all_1.gst-libav
    ];

    extraInstallCommands = ''
      wrapProgram $out/bin/buzz \
        --run 'export CODEX_HOME="''${CODEX_HOME:-$HOME/.config/codex}"' \
        --prefix PATH : ${buzzBrowserLauncher}/bin \
        --set GDK_BACKEND wayland \
        --set GST_PLUGIN_PATH_1_0 \
          ${pkgs.lib.makeSearchPath "lib/gstreamer-1.0" [
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gst_all_1.gst-plugins-good
            pkgs.gst_all_1.gst-plugins-bad
            pkgs.gst_all_1.gst-libav
          ]} \
        --set GST_PLUGIN_SCANNER_1_0 \
          ${pkgs.gst_all_1.gstreamer.out}/libexec/gstreamer-1.0/gst-plugin-scanner

      while IFS= read -r desktopFile; do
        install -Dm444 "$desktopFile" \
          "$out/share/applications/$(basename "$desktopFile")"
        substituteInPlace "$out/share/applications/$(basename "$desktopFile")" \
          --replace-fail 'Exec=buzz-desktop' 'Exec=buzz'
      done < <(find ${buzzContents} -name '*.desktop' -type f)

      install -Dm444 ${buzzContents}/Buzz.png \
        $out/share/icons/hicolor/512x512/apps/buzz-desktop.png

      if [ -d ${buzzContents}/usr/share/icons ]; then
        while IFS= read -r icon; do
          install -Dm444 "$icon" "$out/share/''${icon#${buzzContents}/usr/share/}"
        done < <(find ${buzzContents}/usr/share/icons -type f)
      fi
    '';

    meta = {
      description = "Workspace where people and AI agents build together";
      homepage = "https://buzz.xyz";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "buzz";
      platforms = [ "x86_64-linux" ];
    };
  };

  codex-acp = codexAcp;

  figma-desktop = pkgs.appimageTools.wrapType2 {
    pname = "figma-desktop";
    version = figmaDesktopVersion;
    src = figmaDesktopSrc;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    extraInstallCommands = ''
      wrapProgram $out/bin/figma-desktop \
        --set FIGMA_USE_WAYLAND 1 \
        --run 'export XDG_DATA_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}/figma-desktop-linux/xdg-data"'

      install -Dm444 ${figmaDesktopContents}/io.github.nickvdp.figma-desktop-linux.desktop \
        $out/share/applications/io.github.nickvdp.figma-desktop-linux.desktop
      install -Dm444 ${figmaDesktopContents}/io.github.nickvdp.figma-desktop-linux.png \
        $out/share/icons/hicolor/512x512/apps/io.github.nickvdp.figma-desktop-linux.png
      substituteInPlace $out/share/applications/io.github.nickvdp.figma-desktop-linux.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=figma-desktop'
    '';

    meta = {
      description = "Unofficial Figma desktop application for Linux";
      homepage = "https://github.com/IliyaBrook/figma-linux";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "figma-desktop";
      platforms = [ "x86_64-linux" ];
    };
  };

  paper-desktop = pkgs.appimageTools.wrapType2 {
    pname = "paper-desktop";
    version = paperDesktopVersion;
    src = paperDesktopSrc;

    extraInstallCommands = ''
      install -Dm444 ${paperDesktopContents}/paper-desktop.desktop \
        $out/share/applications/paper-desktop.desktop
      substituteInPlace $out/share/applications/paper-desktop.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=paper-desktop'

      while IFS= read -r icon; do
        install -Dm444 "$icon" "$out/share/''${icon#${paperDesktopContents}/usr/share/}"
      done < <(find ${paperDesktopContents}/usr/share/icons -type f)
    '';

    meta = {
      description = "Collaborative interface design tool";
      homepage = "https://paper.design";
      license = pkgs.lib.licenses.unfree;
      mainProgram = "paper-desktop";
      platforms = [ "x86_64-linux" ];
    };
  };

  t3code = pkgs.appimageTools.wrapType2 {
    pname = "t3code";
    version = t3codeVersion;
    src = t3codeSrc;

    extraInstallCommands = ''
      install -Dm444 ${t3codeContents}/t3code.desktop \
        $out/share/applications/t3code.desktop
      substituteInPlace $out/share/applications/t3code.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=t3code'

      while IFS= read -r icon; do
        install -Dm444 "$icon" "$out/share/''${icon#${t3codeContents}/usr/share/}"
      done < <(find ${t3codeContents}/usr/share/icons -type f)
    '';

    meta = {
      description = "Minimal desktop GUI for coding agents";
      homepage = "https://github.com/pingdotgg/t3code";
      license = pkgs.lib.licenses.mit;
      mainProgram = "t3code";
      platforms = [ "x86_64-linux" ];
    };
  };

  nextcloud-client_4_0_4 = pkgs.nextcloud-client.overrideAttrs (_oldAttrs: {
    version = "4.0.4";
    src = pkgs.fetchFromGitHub {
      owner = "nextcloud-releases";
      repo = "desktop";
      tag = "v4.0.4";
      hash = "sha256-BEjsIx0knmTj6kgM7fsJV5XN660cRe9DbYxeL7YHPRo=";
    };
  });

  dokploy-cli = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "dokploy-cli";
    version = "0.29.4";

    src = pkgs.fetchFromGitHub {
      owner = "Dokploy";
      repo = "cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-WTNzjUP2pMmYnyAPkf5kbnu3CNH0Va1Mk7T7CDtdB/8=";
    };

    pnpmDeps = pkgs.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      fetcherVersion = 3;
      hash = "sha256-RKBF5rxC2mlEZB5p62LH11CZSDF1+DlNwRkh6HSVoWI=";
    };

    nativeBuildInputs = with pkgs; [
      nodejs
      pnpm
      pnpmConfigHook
    ];

    postPatch = ''
      substituteInPlace src/client.ts \
        --replace-fail \
          'const configPath = path.join(__dirname, "..", "config.json");' \
          'const configPath = path.join(process.env.XDG_CONFIG_HOME ?? path.join(process.env.HOME ?? ".", ".config"), "dokploy", "config.json");'
      substituteInPlace src/client.ts \
        --replace-fail \
          'fs.writeFileSync(configPath, JSON.stringify({ url, token }, null, 2));' \
          'fs.mkdirSync(path.dirname(configPath), { recursive: true, mode: 0o700 }); fs.writeFileSync(configPath, JSON.stringify({ url, token }, null, 2), { mode: 0o600 });'
    '';

    buildPhase = ''
      runHook preBuild
      pnpm run build
      substituteInPlace dist/index.js \
        --replace-fail 'version: "0.3.0"' 'version: "${finalAttrs.version}"'
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib/dokploy-cli" "$out/bin"
      cp -r dist package.json node_modules "$out/lib/dokploy-cli/"
      chmod +x "$out/lib/dokploy-cli/dist/index.js"
      ln -s "$out/lib/dokploy-cli/dist/index.js" "$out/bin/dokploy"
      runHook postInstall
    '';
  });

  fallow = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "fallow";
    version = "2.73.0";

    fallowSrc = pkgs.fetchurl {
      url = "https://registry.npmjs.org/fallow/-/fallow-${version}.tgz";
      hash = "sha256-uy7nEbL3aE/5XQgTq/p8j2o2pP7Nv6ZIaBST1oMmK8c=";
    };

    detectLibcSrc = pkgs.fetchurl {
      url = "https://registry.npmjs.org/detect-libc/-/detect-libc-2.1.2.tgz";
      hash = "sha256-Jw3sD8Bs/4ZIHaivLdjxje5rYCeQsU7w4cLBjX2jlCc=";
    };

    linuxX64GnuSrc = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@fallow-cli/linux-x64-gnu/-/linux-x64-gnu-${version}.tgz";
      hash = "sha256-sCg84DDNqVPKHdwz5NbAvdD+jvOCUjWx7+dq7mQEkS0=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      gnutar
      makeWrapper
    ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      mkdir -p \
        "$out/lib/node_modules/fallow" \
        "$out/lib/node_modules/detect-libc" \
        "$out/lib/node_modules/@fallow-cli/linux-x64-gnu"

      tar -xzf ${fallowSrc} -C "$out/lib/node_modules/fallow" --strip-components=1
      tar -xzf ${detectLibcSrc} -C "$out/lib/node_modules/detect-libc" --strip-components=1
      tar -xzf ${linuxX64GnuSrc} -C "$out/lib/node_modules/@fallow-cli/linux-x64-gnu" --strip-components=1

      chmod +x \
        "$out/lib/node_modules/@fallow-cli/linux-x64-gnu/fallow" \
        "$out/lib/node_modules/@fallow-cli/linux-x64-gnu/fallow-lsp" \
        "$out/lib/node_modules/@fallow-cli/linux-x64-gnu/fallow-mcp"

      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/fallow" \
        --add-flags "$out/lib/node_modules/fallow/bin/fallow"
      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/fallow-lsp" \
        --add-flags "$out/lib/node_modules/fallow/bin/fallow-lsp"
      makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/fallow-mcp" \
        --add-flags "$out/lib/node_modules/fallow/bin/fallow-mcp"

      runHook postInstall
    '';

    meta = {
      description = "JS/TS code analysis CLI, LSP server, and MCP server";
      homepage = "https://github.com/fallow-rs/fallow";
      license = pkgs.lib.licenses.mit;
      mainProgram = "fallow";
      platforms = [ "x86_64-linux" ];
    };
  };
}

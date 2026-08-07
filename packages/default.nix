{ pkgs }:
let
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
  t3codeVersion = "0.0.32";
  t3codeSrc = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${t3codeVersion}/T3-Code-${t3codeVersion}-x86_64.AppImage";
    hash = "sha256-SS7ctI7vlzCfNMS3CoEhuGfDronCBowuKLs5Oo2CLCI=";
  };
  t3codeContents = pkgs.appimageTools.extractType2 {
    pname = "t3code";
    version = t3codeVersion;
    src = t3codeSrc;
  };
in
{
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
    version = "0.29.2";

    src = pkgs.fetchFromGitHub {
      owner = "Dokploy";
      repo = "cli";
      tag = "v${finalAttrs.version}";
      hash = "sha256-LH0d7L+xzr+A8QCn/yOpy9UKM4PI47RVZrR4WlZXT6A=";
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

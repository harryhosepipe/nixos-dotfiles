{ pkgs }:
{
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
      hash = "sha256-RSq0VCHLg+umP7SXgvgaBfxXf0Fr6aaUfJksTH50zM0=";
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

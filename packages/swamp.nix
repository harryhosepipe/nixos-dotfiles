{ pkgs }:
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "swamp";
  version = "20261022.021804.0-sha.983e2929";

  src = pkgs.fetchurl {
    url = "https://artifacts.swamp-club.com/swamp/${finalAttrs.version}/binary/linux/x86_64/swamp-${finalAttrs.version}-binary-linux-x86_64.tar.gz";
    hash = "sha256-oEQA4C2dUhHuHT2PCw2EDUnGAxuBP0lG3oztlRI15Mw=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.installShellFiles
    pkgs.makeWrapper
  ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];

  # Preserve the JavaScript and Deno resources embedded in the executable.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 swamp "$out/bin/swamp"
    runHook postInstall
  '';

  # Append a hook so autoPatchelfHook fixes the interpreter before execution.
  preFixup = ''
    postFixupHooks+=(installSwampCompletions)
    installSwampCompletions() {
      # Nix manages updates. Deno on PATH is upstream's fallback when its
      # extracted runtime cannot execute; xdg-open handles browser sign-in.
      wrapProgram "$out/bin/swamp" \
        --set SWAMP_NO_UPDATE_CHECK 1 \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.deno pkgs.git pkgs.xdg-utils ]}

      # Keep completion generation independent of the builder's home directory.
      export SWAMP_HOME="$TMPDIR/swamp-completions"
      export SWAMP_NO_TELEMETRY=1
      "$out/bin/swamp" completions bash > "$TMPDIR/swamp.bash"
      "$out/bin/swamp" completions zsh > "$TMPDIR/swamp.zsh"
      "$out/bin/swamp" completions fish > "$TMPDIR/swamp.fish"
      installShellCompletion --cmd swamp \
        --bash "$TMPDIR/swamp.bash" \
        --zsh "$TMPDIR/swamp.zsh" \
        --fish "$TMPDIR/swamp.fish"
    }
  '';

  meta = {
    description = "Automation framework for AI agents";
    homepage = "https://swamp-club.com";
    license = pkgs.lib.licenses.agpl3Only;
    mainProgram = "swamp";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
  };
})

{ pkgs }:
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vercel-cli";
  version = "65.2.0";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@vercel/vc-native-linux-x64/-/vc-native-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-+UCaiEpFrnBbzhAatBX+6AxUAPsZp8lxhXegC+h7q2w=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
  buildInputs = [ pkgs.stdenv.cc.cc.lib ];
  # Preserve the JavaScript payload embedded in the native executable.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/vercel "$out/libexec/vercel"
    makeWrapper "$out/libexec/vercel" "$out/bin/vercel" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.nodejs_24 ]}
    ln -s vercel "$out/bin/vc"
    runHook postInstall
  '';

  meta = {
    description = "Command-line interface for Vercel";
    homepage = "https://vercel.com/docs/cli";
    license = pkgs.lib.licenses.asl20;
    mainProgram = "vercel";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ];
  };
})

{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, installShellFiles
, getent
, iproute2
, iptables
, shadow
, procps
}:

# Use upstream's static binaries so Tailscale can follow stable releases
# independently of this configuration's pinned nixpkgs and Go compiler.
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "tailscale";
  version = "1.104.1";

  src = fetchurl {
    url = "https://pkgs.tailscale.com/stable/tailscale_${finalAttrs.version}_amd64.tgz";
    hash = "sha256-EI0dluz0ENMFVx4XNRbycDj4cJGam4nJFKFnxtM6RSg=";
  };

  nativeBuildInputs = [ makeWrapper installShellFiles ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 tailscale "$out/bin/tailscale"
    install -Dm755 tailscaled "$out/bin/tailscaled"
    wrapProgram "$out/bin/tailscaled" \
      --prefix PATH : ${lib.makeBinPath [ getent iproute2 iptables shadow ]} \
      --suffix PATH : ${lib.makeBinPath [ procps ]}

    install -Dm644 systemd/tailscaled.service "$out/lib/systemd/system/tailscaled.service"
    substituteInPlace "$out/lib/systemd/system/tailscaled.service" \
      --replace-fail /usr/sbin/tailscaled "$out/bin/tailscaled"
    sed -i '/^EnvironmentFile=/d' "$out/lib/systemd/system/tailscaled.service"

    installShellCompletion --cmd tailscale \
      --bash <("$out/bin/tailscale" completion bash) \
      --fish <("$out/bin/tailscale" completion fish) \
      --zsh <("$out/bin/tailscale" completion zsh)

    runHook postInstall
  '';

  meta = {
    description = "Node agent for Tailscale, a mesh VPN built on WireGuard";
    homepage = "https://tailscale.com";
    changelog = "https://tailscale.com/changelog#2026-10-07-client";
    license = lib.licenses.bsd3;
    mainProgram = "tailscale";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

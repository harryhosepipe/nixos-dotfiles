{ pkgs, ... }:
let
  piVersion = "0.87.1";

  piPackage = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = piVersion;

    src = ../../nix/pi-npm;
    npmDepsHash = "sha256-iG+2hlOqUNQGK2hURsRw6X0YMT3+pxRMs17MOU40xJo=";
    npmDepsFetcherVersion = 2;

    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/pi-coding-agent" "$out/bin"
      cp -r node_modules package.json package-lock.json "$out/lib/pi-coding-agent/"

      makeWrapper ${pkgs.nodejs_24}/bin/node "$out/bin/pi" \
        --add-flags "$out/lib/pi-coding-agent/node_modules/@earendil-works/pi-coding-agent/dist/bundle/cli.js" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}

      runHook postInstall
    '';

    meta.mainProgram = "pi";
  };

  pi = pkgs.writeShellScriptBin "pi" ''
    unset PI_CODING_AGENT_DIR PI_CODING_AGENT_SESSION_DIR PI_PACKAGE_DIR
    exec ${piPackage}/bin/pi "$@"
  '';
in
{
  home.packages = [
    pi
  ];

  # Keep editable declarative resources in the dotfiles repo while Pi owns
  # credentials, settings, sessions, and other runtime state in ~/.pi/agent.
  dotfiles.homeFiles = {
    ".pi/agent/AGENTS.md" = "pi/AGENTS.md";
    ".pi/agent/mcp.json" = "pi/mcp.json";
    ".pi/agent/extensions/mcp-bridge" = "pi/extensions/mcp-bridge";
  };
}

{ pkgs, ... }:
let
  piVersion = "0.83.0";

  piPackage = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    version = piVersion;

    src = ../../nix/pi-npm;
    npmDepsHash = "sha256-akHVCJv815QCoo580q44irk3XqpQ8oxtxHmWVof/msg=";
    npmDepsFetcherVersion = 2;

    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/pi-coding-agent" "$out/bin"
      cp -r node_modules package.json package-lock.json "$out/lib/pi-coding-agent/"

      makeWrapper ${pkgs.nodejs_24}/bin/node "$out/bin/pi" \
        --add-flags "$out/lib/pi-coding-agent/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" \
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

{ inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstreamRoot = inputs.hermes-agent.outPath;

  # Hermes' current main branch has two packaging defects. Electron replaced
  # its v41.7.2 headers archive without changing the URL, and the TUI source
  # filter omits apps/shared. Keep these patches narrow and fail explicitly
  # when upstream changes either target, so they can be removed safely.
  upstreamTuiSource = builtins.readFile "${upstreamRoot}/nix/tui.nix";
  hermesTuiSource =
    assert lib.hasInfix "dirs = [ \"ui-tui\" ];" upstreamTuiSource;
    pkgs.writeText "hermes-tui-patched.nix" (builtins.replaceStrings
      [ "dirs = [ \"ui-tui\" ];" ]
      [ "dirs = [ \"ui-tui\" \"apps/shared\" ];" ]
      upstreamTuiSource);

  upstreamDesktopSource = builtins.readFile "${upstreamRoot}/nix/desktop.nix";
  hermesDesktopSource =
    assert lib.hasInfix "sha256-zi/QMwRZ0+FwE9XTE+DiSIeJXAwxmLKEaBWD5W3pMOI=" upstreamDesktopSource;
    pkgs.writeText "hermes-desktop-patched.nix" (builtins.replaceStrings
      [ "sha256-zi/QMwRZ0+FwE9XTE+DiSIeJXAwxmLKEaBWD5W3pMOI=" ]
      [ "sha256-0nUJBQDEikyYntZwq+ycH32mzEQtQmz3ICz9eeTMpJk=" ]
      upstreamDesktopSource);

  upstreamAgentSource = builtins.readFile "${upstreamRoot}/nix/hermes-agent.nix";
  hermesAgentSource =
    assert lib.hasInfix "callPackage ./tui.nix" upstreamAgentSource;
    pkgs.writeText "hermes-agent-patched.nix" (builtins.replaceStrings
      [
        "  rev ? null,\n"
        "callPackage ./python.nix"
        "callPackage ./lib.nix"
        "callPackage ./tui.nix"
        "callPackage ./web.nix"
        "src = ../skills;"
        "src = ../optional-skills;"
        "src = ../plugins;"
        "lib.cleanSource ../locales"
        "builtins.readFile ../pyproject.toml"
        "callPackage ./desktop.nix"
      ]
      [
        "  rev ? null,\n  tuiSource ? ./tui.nix,\n  desktopSource ? ./desktop.nix,\n"
        "callPackage ${upstreamRoot}/nix/python.nix"
        "callPackage ${upstreamRoot}/nix/lib.nix"
        "callPackage tuiSource"
        "callPackage ${upstreamRoot}/nix/web.nix"
        "src = ${upstreamRoot}/skills;"
        "src = ${upstreamRoot}/optional-skills;"
        "src = ${upstreamRoot}/plugins;"
        "lib.cleanSource ${upstreamRoot}/locales"
        "builtins.readFile ${upstreamRoot}/pyproject.toml"
        "callPackage desktopSource"
      ]
      upstreamAgentSource);

  hermesAgentBase = pkgs.callPackage hermesAgentSource {
    uv2nix = inputs.hermes-uv2nix;
    pyproject-nix = inputs.hermes-pyproject-nix;
    pyproject-build-systems = inputs.hermes-pyproject-build-systems;
    npm-lockfile-fix = inputs.hermes-npm-lockfile-fix.packages.${system}.default;
    rev = inputs.hermes-agent.rev or null;
    tuiSource = hermesTuiSource;
    desktopSource = hermesDesktopSource;
  };
  hermesAgent = hermesAgentBase.override {
    extraDependencyGroups = [
      "anthropic"
      "azure-identity"
      "bedrock"
      "daytona"
      "dingtalk"
      "edge-tts"
      "exa"
      "fal"
      "feishu"
      "firecrawl"
      "hindsight"
      "honcho"
      "messaging"
      "modal"
      "parallel-web"
      "tts-premium"
      "voice"
    ] ++ lib.optionals pkgs.stdenv.isLinux [ "matrix" ];
  };
  hermesDesktop = hermesAgent.hermesDesktop;
in
{
  home.packages = [
    hermesDesktop
  ];

  xdg.desktopEntries.hermes-desktop = {
    name = "Hermes Desktop";
    exec = "${hermesDesktop}/bin/hermes-desktop";
    terminal = false;
    categories = [ "Utility" ];
  };
}

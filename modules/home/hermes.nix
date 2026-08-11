{ inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  upstreamRoot = inputs.hermes-agent.outPath;

  # Electron replaced its v41.7.2 headers archive without changing the URL.
  upstreamDesktopSource = builtins.readFile "${upstreamRoot}/nix/desktop.nix";
  hermesDesktopSource =
    assert lib.hasInfix "sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=" upstreamDesktopSource;
    pkgs.writeText "hermes-desktop-patched.nix" (builtins.replaceStrings
      [ "sha256-f8bSbLRmtbP93CJAvEBs+sHWDZ1xP2bcpLhC1EnOmZU=" ]
      [ "sha256-0nUJBQDEikyYntZwq+ycH32mzEQtQmz3ICz9eeTMpJk=" ]
      upstreamDesktopSource);

  upstreamAgentSource = builtins.readFile "${upstreamRoot}/nix/hermes-agent.nix";
  hermesAgentSource =
    assert lib.hasInfix "callPackage ./desktop.nix" upstreamAgentSource;
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
        "src = ../optional-mcps;"
        "lib.cleanSource ../locales"
        "builtins.readFile ../pyproject.toml"
        "callPackage ./desktop.nix"
      ]
      [
        "  rev ? null,\n  desktopSource ? ./desktop.nix,\n"
        "callPackage ${upstreamRoot}/nix/python.nix"
        "callPackage ${upstreamRoot}/nix/lib.nix"
        "callPackage ${upstreamRoot}/nix/tui.nix"
        "callPackage ${upstreamRoot}/nix/web.nix"
        "src = ${upstreamRoot}/skills;"
        "src = ${upstreamRoot}/optional-skills;"
        "src = ${upstreamRoot}/plugins;"
        "src = ${upstreamRoot}/optional-mcps;"
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

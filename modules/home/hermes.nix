{ inputs
, lib
, pkgs
, ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  hermesAgentBase = inputs.hermes-agent.packages.${system}.default;
  hermesAgent = hermesAgentBase.override {
    version = "0.22.5";
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

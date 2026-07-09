{ config
, inputs
, pkgs
, userSettings
, ...
}:

let
  # This package comes from the codex-cli-nix flake input.
  # Updating that input in flake.lock is what moves Codex to a newer release.
  codex = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # These are the active Codex skills from github:mattpocock/skills.
  # Deprecated skills are left out so they do not appear as normal choices.
  mattPocockSkills = {
    diagnose = "engineering/diagnosing-bugs";
    grill-with-docs = "engineering/grill-with-docs";
    improve-codebase-architecture = "engineering/improve-codebase-architecture";
    setup-matt-pocock-skills = "engineering/setup-matt-pocock-skills";
    tdd = "engineering/tdd";
    to-spec = "engineering/to-spec";
    to-tickets = "engineering/to-tickets";
    triage = "engineering/triage";
    git-guardrails-claude-code = "misc/git-guardrails-claude-code";
    migrate-to-shoehorn = "misc/migrate-to-shoehorn";
    scaffold-exercises = "misc/scaffold-exercises";
    setup-pre-commit = "misc/setup-pre-commit";
    edit-article = "personal/edit-article";
    obsidian-vault = "personal/obsidian-vault";
    wayfinder = "engineering/wayfinder";
    write-a-skill = "productivity/writing-great-skills";
  };

  mattPocockSkillFiles = builtins.listToAttrs (
    map
      (name: {
        name = "codex/skills/${name}";
        value.source = "${inputs.mattpocock-skills}/skills/${mattPocockSkills.${name}}";
      })
      (builtins.attrNames mattPocockSkills)
  );
in
{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];

  home.packages = [
    codex
    pkgs.libnotify
  ];

  home.sessionVariables = {
    CODEX_HOME = "${config.xdg.configHome}/codex";
  };

  dotfiles.configEntries = {
    "codex/AGENTS.md" = "codex/AGENTS.md";
    "codex/config.toml" = "codex/config.toml";
    "codex/agents" = "codex/agents";
    "codex/hooks.json" = "codex/hooks.json";
    "codex/hooks" = "codex/hooks";
  };

  xdg.configFile = mattPocockSkillFiles;

  programs.codexDesktopLinux = {
    enable = true;
    computerUseUi.enable = true;
    remoteMobileControl.enable = true;
    remoteControl = {
      enable = true;
      package = codex;
      codexHome = "${config.xdg.configHome}/codex";
      extraPackages = [
        pkgs.bash
        pkgs.coreutils
        pkgs.ydotool
      ];
    };
  };
}

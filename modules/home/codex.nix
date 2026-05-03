{ config
, inputs
, pkgs
, userSettings
, ...
}:

let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  # This package comes from the codex-cli-nix flake input.
  # Updating that input in flake.lock is what moves Codex to a newer release.
  codex = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # These are the active Codex skills from github:mattpocock/skills.
  # Deprecated skills are left out so they do not appear as normal choices.
  mattPocockSkills = {
    diagnose = "engineering/diagnose";
    grill-with-docs = "engineering/grill-with-docs";
    improve-codebase-architecture = "engineering/improve-codebase-architecture";
    setup-matt-pocock-skills = "engineering/setup-matt-pocock-skills";
    tdd = "engineering/tdd";
    to-issues = "engineering/to-issues";
    to-prd = "engineering/to-prd";
    triage = "engineering/triage";
    zoom-out = "engineering/zoom-out";
    git-guardrails-claude-code = "misc/git-guardrails-claude-code";
    migrate-to-shoehorn = "misc/migrate-to-shoehorn";
    scaffold-exercises = "misc/scaffold-exercises";
    setup-pre-commit = "misc/setup-pre-commit";
    edit-article = "personal/edit-article";
    obsidian-vault = "personal/obsidian-vault";
    caveman = "productivity/caveman";
    grill-me = "productivity/grill-me";
    write-a-skill = "productivity/write-a-skill";
  };

  mattPocockSkillFiles =
    builtins.listToAttrs
      (builtins.map
        (name: {
          name = "codex/skills/${name}";
          value.source = "${inputs.mattpocock-skills}/skills/${mattPocockSkills.${name}}";
        })
        (builtins.attrNames mattPocockSkills));
in
{
  home.packages = [
    codex
  ];

  home.sessionVariables = {
    CODEX_HOME = "${config.xdg.configHome}/codex";
  };

  xdg.configFile =
    {
      "codex/AGENTS.md".source =
        createSymlink "${dotfiles}/codex/AGENTS.md";

      "codex/config.toml".source =
        createSymlink "${dotfiles}/codex/config.toml";

      "codex/agents".source =
        createSymlink "${dotfiles}/codex/agents";

      "codex/hooks.json".source =
        createSymlink "${dotfiles}/codex/hooks.json";
    }
    // mattPocockSkillFiles;
}

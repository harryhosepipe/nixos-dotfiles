{ config
, inputs
, pkgs
, userSettings
, ...
}:

let
  codex = pkgs.buildNpmPackage {
    pname = "codex-cli";
    version = "0.147.0";

    src = ../../nix/codex-npm;
    npmDepsHash = "sha256-pTr0xEpkwEV7CK3vuJ4MxhhkFB1y0+b/kvFBOHvf8/Q=";

    dontNpmBuild = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib/codex-cli" "$out/bin"
      cp -r node_modules package.json package-lock.json "$out/lib/codex-cli/"

      makeWrapper ${pkgs.nodejs_22}/bin/node "$out/bin/codex" \
        --add-flags "$out/lib/codex-cli/node_modules/@openai/codex/bin/codex.js" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bubblewrap ]}

      if [ ! -e "$out/bin/codex-code-mode-host" ]; then
        ln -s codex "$out/bin/codex-code-mode-host"
      fi

      runHook postInstall
    '';

    meta.mainProgram = "codex";
  };

  # These are the active Codex skills from github:mattpocock/skills.
  # Deprecated skills are left out so they do not appear as normal choices.
  # Destination directory names are read from each SKILL.md rather than duplicated
  # here, because Codex requires the directory and manifest names to agree.
  mattPocockSkillPaths = [
    "engineering/code-review"
    "engineering/diagnosing-bugs"
    "engineering/domain-modeling"
    "engineering/grill-with-docs"
    "engineering/implement"
    "engineering/improve-codebase-architecture"
    "engineering/prototype"
    "engineering/research"
    "engineering/setup-matt-pocock-skills"
    "engineering/tdd"
    "engineering/to-spec"
    "engineering/to-tickets"
    "engineering/triage"
    "misc/git-guardrails-claude-code"
    "misc/migrate-to-shoehorn"
    "misc/scaffold-exercises"
    "misc/setup-pre-commit"
    "personal/edit-article"
    "personal/obsidian-vault"
    "engineering/wayfinder"
    "productivity/writing-great-skills"
  ];

  skillName = path:
    let
      manifest = "${inputs.mattpocock-skills}/skills/${path}/SKILL.md";
      nameLines = builtins.filter
        (line: builtins.match "name:[[:space:]]*.*" line != null)
        (pkgs.lib.splitString "\n" (builtins.readFile manifest));
    in
    if builtins.length nameLines != 1 then
      throw "Expected exactly one top-level name in ${manifest}"
    else
      builtins.elemAt (builtins.match "name:[[:space:]]*(.*)" (builtins.head nameLines)) 0;

  mattPocockSkillFiles = builtins.listToAttrs (
    map
      (path:
        let name = skillName path;
        in {
          name = "codex/skills/${name}";
          value.source = "${inputs.mattpocock-skills}/skills/${path}";
        })
      mattPocockSkillPaths
  );

  skillNamesAreUnique =
    builtins.length (builtins.attrNames mattPocockSkillFiles)
    == builtins.length mattPocockSkillPaths;
in
{
  imports = [
    inputs.codex-desktop-linux.homeManagerModules.default
  ];

  assertions = [
    {
      assertion = skillNamesAreUnique;
      message = "Matt Pocock's selected skills must have unique names in their SKILL.md files";
    }
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

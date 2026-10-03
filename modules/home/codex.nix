{ config
, inputs
, pkgs
, ...
}:

let
  codexHome = "${config.xdg.configHome}/codex";
  desktopPackage = inputs.codex-desktop-linux.packages.${pkgs.stdenv.hostPlatform.system}.codex-desktop.override {
    enableComputerUseUi = config.programs.codexDesktopLinux.computerUseUi.enable;
  };
  desktopResources = "${desktopPackage}/opt/codex-desktop/resources";
  nodeModules = "${desktopResources}/cua_node/lib/node_modules";
  trustedServices = builtins.toJSON {
    browser = "${desktopResources}/plugins/openai-bundled/plugins/browser/scripts/browser-service.mjs";
    sky = "@oai/sky/service";
  };

  # Expose Desktop's bundled tools without installing a second CLI. Keep the
  # real code-mode helper alongside codex, and derive computer-use paths from
  # the same Desktop package so they follow upgrades automatically.
  codex = pkgs.runCommand "codex-desktop-tools-${desktopPackage.version}" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "codex";
  } ''
    test -x ${desktopResources}/codex
    test -x ${desktopResources}/codex-code-mode-host
    test -x ${desktopResources}/cua_node/bin/node_repl
    test -f ${desktopResources}/plugins/openai-bundled/plugins/browser/scripts/browser-service.mjs
    mkdir -p "$out/bin"
    makeWrapper ${desktopResources}/codex "$out/bin/codex" \
      --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.bubblewrap ]} \
      --set-default CODEX_HOME ${pkgs.lib.escapeShellArg codexHome}
    ln -s ${desktopResources}/codex-code-mode-host "$out/bin/codex-code-mode-host"
    makeWrapper ${desktopResources}/cua_node/bin/node_repl "$out/bin/codex-node-repl" \
      --set CODEX_HOME ${pkgs.lib.escapeShellArg codexHome} \
      --set NODE_REPL_NODE_MODULE_DIRS ${nodeModules} \
      --set NODE_REPL_NODE_PATH ${desktopResources}/cua_node/bin/node \
      --set NODE_REPL_TRUSTED_CODE_PATHS ${pkgs.lib.escapeShellArg "${codexHome}:${nodeModules}:${desktopResources}/plugins"} \
      --set NODE_REPL_TRUSTED_SERVICES ${pkgs.lib.escapeShellArg trustedServices} \
      --set BROWSER_USE_CODEX_APP_VERSION ${desktopPackage.version} \
      --set CODEX_CLI_PATH ${desktopResources}/codex
  '';

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
    CODEX_HOME = codexHome;
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
    package = desktopPackage;
    computerUseUi.enable = true;
    # The official Linux app's remote-control proxy currently times out during
    # its initialize handshake. Keep it disabled until upstream fixes it.
    remoteMobileControl.enable = false;
    remoteControl.enable = false;
  };
}

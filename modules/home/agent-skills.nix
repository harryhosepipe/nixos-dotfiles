{ inputs
, lib
, ...
}:

let
  # Follow the skill set Matt ships in his Claude Code plugin, so promoted,
  # graduated, and retired skills track the pinned flake input automatically.
  # Several of these call each other through the Skill tool (for example,
  # grill-with-docs, triage, and wayfinder all invoke "grilling"), so installing
  # the whole set keeps those hand-offs working.
  pluginSkillPaths = map
    (path: lib.removePrefix "./skills/" path)
    (builtins.fromJSON (builtins.readFile "${inputs.mattpocock-skills}/.claude-plugin/plugin.json")).skills;

  # Frozen misc/ skills are not in the plugin but still work as-is upstream.
  extraSkillPaths = [
    "misc/git-guardrails-claude-code"
    "misc/migrate-to-shoehorn"
    "misc/scaffold-exercises"
    "misc/setup-pre-commit"
  ];

  mattPocockSkillPaths = pluginSkillPaths ++ extraSkillPaths;

  # Claude Code ships a built-in /code-review that the same-named skill would
  # collide with.
  claudeExcludedPaths = [
    "engineering/code-review"
  ];

  skillName = path:
    let
      manifest = "${inputs.mattpocock-skills}/skills/${path}/SKILL.md";
      nameLines = builtins.filter
        (line: builtins.match "name:[[:space:]]*.*" line != null)
        (lib.splitString "\n" (builtins.readFile manifest));
    in
    if builtins.length nameLines != 1 then
      throw "Expected exactly one top-level name in ${manifest}"
    else
      builtins.elemAt (builtins.match "name:[[:space:]]*(.*)" (builtins.head nameLines)) 0;

  # Link each skill individually so tool-managed entries in the same directory
  # (such as Claude's synced/ and .trash/) are left alone.
  skillLinks = prefix: paths: builtins.listToAttrs (
    map
      (path: {
        name = "${prefix}/${skillName path}";
        value.source = "${inputs.mattpocock-skills}/skills/${path}";
      })
      paths
  );

  codexSkillFiles = skillLinks "codex/skills" mattPocockSkillPaths;

  claudeSkillFiles = skillLinks ".claude/skills"
    (builtins.filter (path: !(builtins.elem path claudeExcludedPaths)) mattPocockSkillPaths);

  skillNamesAreUnique =
    builtins.length (builtins.attrNames codexSkillFiles)
    == builtins.length mattPocockSkillPaths;
in
{
  assertions = [
    {
      assertion = skillNamesAreUnique;
      message = "Matt Pocock's selected skills must have unique names in their SKILL.md files";
    }
  ];

  xdg.configFile = codexSkillFiles;
  home.file = claudeSkillFiles;
}

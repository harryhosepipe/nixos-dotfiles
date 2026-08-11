# Zed configuration instructions

- Treat `config/zed` as the tracked source for Zed customization. Home Manager
  deploys it recursively to `~/.config/zed`.
- Read and maintain `MIGRATION.md` while changing settings or keybindings.
- Test related keybindings incrementally and document errors, incompatibilities,
  and their resolutions in `MIGRATION.md`.
- Do not commit Zed runtime state, sessions, caches, credentials, or API keys.

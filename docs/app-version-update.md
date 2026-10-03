# Application version update — 2026-09-06

| Application | Configured version | Result |
| --- | --- | --- |
| Pi | 0.85.1 | Updated from 0.84.3 |
| Codex CLI | 0.153.4 | Updated from 0.153.0 |
| Codex Desktop | 26.901.51231 | Updated Linux packaging input to revision 80366e51b5d7068951017a30f07a3499758fb2ac |
| Hermes Desktop | 0.17.0 | Already current in stable Hermes release v2026.8.31 |
| T3 Code | 0.0.38 | Already the latest stable release |

Version checks used the upstream npm registry and GitHub APIs:

- [Pi npm metadata](https://registry.npmjs.org/@earendil-works/pi-coding-agent/latest)
- [Codex CLI npm metadata](https://registry.npmjs.org/@openai/codex/latest)
- [Codex Desktop packaging revision](https://github.com/ilysenko/codex-desktop-linux/commit/80366e51b5d7068951017a30f07a3499758fb2ac)
- [Hermes stable release](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.8.31)
- [T3 Code stable release](https://github.com/pingdotgg/t3code/releases/tag/v0.0.38)

Updated the Pi and Codex npm manifests, lockfiles, and Nix dependency hashes; the Codex CLI flake pin; and both Codex Desktop upstream locks. Five Pi transitive dependencies lacked integrity entries in npm's generated lockfile, so their published npm integrity values were added. Existing unrelated local changes were preserved.

Validation passed: all three updated packages built, `pi --version` returned `0.85.1`, `codex --version` returned `codex-cli 0.153.4`, full NixOS and Home Manager activation derivations evaluated, and `git diff --check` passed. The built Codex Desktop entry targets its Nix launcher, whose Wayland flags remain enabled when `NIXOS_OZONE_WL` and `WAYLAND_DISPLAY` are set.

The configuration has not been activated, and the new desktop process has not been launched or checked with `hyprctl clients`. Apply from the repository with:

```sh
sudo nixos-rebuild switch --flake /home/pablo/nix-dot#desktop
```

After activation, fully quit and reopen desktop applications so their processes use the new packages. The rebuild also applies other pending changes in this working tree.

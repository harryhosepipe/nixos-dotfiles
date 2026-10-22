# Application update — 2026-09-10

| Application | Version | Result |
| --- | --- | --- |
| Codex Desktop | 26.903.71938 | Updated from 26.901.51231 |
| Hermes Desktop | 0.17.0 | Updated source to stable Hermes v2026.9.7; desktop version unchanged |
| T3 Code | 0.0.40 | Updated from 0.0.38 |
| Pi | 0.85.1 | Already latest |
| Codex CLI | 0.154.0 | Updated from 0.153.4 |

Versions verified through upstream APIs:

- [Pi npm metadata](https://registry.npmjs.org/@earendil-works/pi-coding-agent/latest)
- [Codex CLI npm metadata](https://registry.npmjs.org/@openai/codex/latest)
- [Codex Desktop packaging revision](https://github.com/ilysenko/codex-desktop-linux/commit/787dbd51268d7bc817304e50b64eed31426f061d)
- [Hermes stable release](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.9.7)
- [T3 Code stable release](https://github.com/pingdotgg/t3code/releases/tag/v0.0.40)

Updated the relevant flake pins and locks, Codex npm manifest and lockfile, and Codex npm/T3 source hashes. Existing unrelated working-tree changes were preserved.

Validation passed: all five configured packages built; `codex --version` returned `codex-cli 0.154.0`; `pi --version` returned `0.85.1`; full NixOS and Home Manager activation derivations evaluated after the final hash update; `git diff --check` passed. Desktop entries target the packaged launchers. Codex Desktop retains native Wayland flags, T3's AppRun does not force X11, and Hermes uses the Nix Electron launcher.

The configuration has not been activated, and new desktop processes have not been tested. Apply with:

```sh
sudo nixos-rebuild switch --flake /home/pablo/nix-dot#desktop
```

This also applies other pending configuration changes. After activation, fully quit and reopen desktop applications, then inspect the new process environments and `hyprctl clients` to verify native Wayland behavior.

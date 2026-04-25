# AGENTS.md

This repo is a learning-first NixOS setup.

The goal is not to be clever.
The goal is to stay clear, calm, and easy to grow.

Anyone working in this repo should treat it like a house that is still being built:
start with a strong shared base, then add clearly named rooms for each machine.

## How To Speak Here

- Use plain language.
- Explain things as if talking to someone who is learning Nix and is not a coder yet.
- Do not use heavy jargon unless the user asks for it.
- When a technical word is necessary, explain it in simple words right away.
- Prefer short explanations that answer:
  what changed, why it matters, and where it lives.

## What This Repo Looks Like Today

Right now the repo is still in an early single-machine shape.

Main pieces:

- `flake.nix`: the front door that builds the system.
- `configuration.nix`: the main machine setup.
- `hardware-configuration.nix`: machine-specific hardware details.
- `home.nix`: user-level setup.
- `git.nix` and `codex.nix`: small focused add-ons.
- `shells/settings.nix`: shared shell choices and shortcuts.
- `config/`: app settings like Neovim, Qtile, Fish, Zsh, and similar files.

This is a good starting point, but the long-term target is bigger than one machine.

## Long-Term Shape

Work toward a layout with:

- one shared base for things used everywhere
- one desktop layer
- one homelab layer
- one laptop layer
- one place for each host to say “I use these shared parts”

That means future changes should move the repo toward:

- shared things live in one shared place
- machine-only things live in that machine's own place
- user app settings stay easy to find
- names should say what something is for without needing detective work

## Rules For Future Changes

- Keep changes small and easy to trace.
- Prefer one clear file over many tiny files when the split does not help learning.
- Do not hide important behavior behind clever tricks.
- Do not mix shared settings and machine-only settings in the same file unless the file is still very small.
- If a setting will be reused by desktop, laptop, and homelab, move it toward a shared place.
- If a setting only makes sense on one machine, keep it in that machine's layer.
- Keep file and folder names boring and obvious.
- When adding a new folder, explain in simple words why it exists.
- Leave short comments only when they help a learner understand the shape.
- When editing Nix files or shell config files, add useful plain-language comments where they help explain startup order, shared values, or why something must be loaded in a certain place.

## Preferred Direction For Refactors

When reorganizing this repo, prefer a path like this:

1. Pull shared settings out of `configuration.nix` into clearly named shared files.
2. Create separate host folders for desktop, homelab, and laptop.
3. Let each host import the shared base plus its own machine-specific files.
4. Split home setup the same way only when the current single `home.nix` starts feeling crowded.

Do not rush into a deep folder tree too early.
A simple structure that can grow is better than a “perfect” structure that is hard to read.

## Guardrails

- Do not rewrite the whole repo just to make it look more advanced.
- Do not rename large parts unless it clearly improves navigation.
- Do not move generated or personal app state into the learning structure on purpose.
- Treat `hardware-configuration.nix` as machine-tied unless the user asks otherwise.
- Keep rebuild commands and common entry points easy to spot.

## Definition Of Success

This repo is in good shape when:

- a learner can tell where to add a shared setting
- a learner can tell where to add a desktop-only setting
- a learner can tell where to add a laptop-only setting
- the top level is not crowded
- future growth feels like adding labeled boxes, not untangling knots

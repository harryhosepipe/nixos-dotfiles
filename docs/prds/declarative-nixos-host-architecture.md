## Problem Statement

This NixOS setup currently works for the main desktop, but the structure is starting to make future machines harder to add. The desktop, future laptop, and future home server need a shared base without copying large host files or mixing unrelated concerns.

The current pattern has useful pieces already: a host registry, shared system settings, Home Manager modules, system modules, and host-local machine files. The friction is that the seams are inconsistent. Some shared behavior lives in host files, some host-only behavior lives next to reusable modules, and some profiles span both NixOS and Home Manager without one clear place to understand them.

## Solution

Reshape the repo around clear host declarations and reusable profiles.

The host registry becomes the place where all machines are declared. The flake builds all declared hosts from that registry instead of hard-coding only the desktop. Shared system and shared home behavior move behind stable profile modules. Desktop-specific GUI behavior becomes a named desktop profile. Server/app workload modules become distinct from the Docker runtime. Host hardware and one-off host behavior stay local to the host folder.

The single-GPU VFIO setup remains desktop-only. It should stay understandable and local to the current desktop host, not become a generic cross-host abstraction unless another real host needs a second adapter later.

## User Stories

1. As the desktop owner, I want the current desktop build to keep evaluating, so that architecture cleanup does not break my working machine.
2. As the desktop owner, I want the desktop host to stay easy to find, so that I can quickly inspect the real machine configuration.
3. As the future laptop owner, I want to add a laptop host with minimal duplicated boilerplate, so that laptop setup starts from the shared base.
4. As the future home server owner, I want to add a server host without desktop GUI defaults, so that server configuration stays small and headless.
5. As a repo maintainer, I want every host declared in one host registry, so that supported machines are visible in one place.
6. As a repo maintainer, I want the flake to build host configurations from the registry, so that adding a host does not require copying flake output logic.
7. As a repo maintainer, I want host declarations to include host name, system architecture, user, and host path, so that host metadata is explicit.
8. As a repo maintainer, I want shared NixOS base settings separate from host hardware, so that global defaults are not mixed with machine details.
9. As a repo maintainer, I want shared Home Manager behavior in a reusable home profile, so that user-wide shell, editor, Git, Codex, and package defaults are not copied per host.
10. As a desktop user, I want GUI session behavior grouped as a desktop profile, so that Hyprland, greetd, portals, cursor, GTK, dconf, and desktop config symlinks are understood together.
11. As a laptop user, I want to reuse the desktop profile if desired, so that laptop GUI setup does not require rediscovering all desktop pieces.
12. As a server user, I want to skip the desktop profile cleanly, so that server evaluation does not pull in GUI packages or session config.
13. As a repo maintainer, I want Docker runtime setup separate from specific app deployments, so that future server apps can reuse Docker without copying app-specific config.
14. As a repo maintainer, I want the Manifest app deployment to be named as an app workload, so that Docker app modules do not hide under generic runtime naming.
15. As a desktop owner, I want the single-GPU VFIO setup to remain tied to the current desktop, so that it does not pretend to be reusable before another host needs it.
16. As a desktop owner, I want VFIO PCI IDs and VM names to stay host-local, so that machine-specific hardware details do not leak into shared modules.
17. As a repo maintainer, I want host files to read as small adapters, so that they mainly choose profiles and set host-specific values.
18. As a repo maintainer, I want reusable profiles to expose a small interface, so that callers do not need to know implementation details.
19. As a repo maintainer, I want modules to have enough depth, so that changing one concept has locality instead of forcing edits across many files.
20. As a repo maintainer, I want shallow pass-through modules avoided, so that module count does not increase without reducing complexity.
21. As a repo maintainer, I want host additions to follow a visible checklist, so that future laptop and server setup is predictable.
22. As a repo maintainer, I want build targets for all hosts to be obvious, so that evaluation can be verified before switching systems.
23. As a repo maintainer, I want shared package allowlists and unfree policy to remain shared where appropriate, so that Home Manager and NixOS evaluation keep using the same package policy.
24. As a repo maintainer, I want comments to explain non-obvious structure, so that the repo remains learning-friendly without documenting every line.
25. As a future contributor, I want a clear directory layout, so that I can tell whether a file is shared, profile-specific, workload-specific, or host-specific.

## Implementation Decisions

- Build or modify a host registry module that is the source of truth for declared machines.
- Modify flake output construction so NixOS configurations are generated from declared hosts.
- Keep user identity and stable host metadata explicit in data, not scattered across module implementations.
- Build or modify a shared system base module for settings that should apply to every machine.
- Build or modify a shared Home Manager profile for user-wide defaults that should follow the same user across machines.
- Build or modify a desktop profile with both NixOS and Home Manager pieces represented in predictable locations.
- Keep desktop GUI behavior reusable for desktop/laptop, but optional for server.
- Split Docker runtime capability from concrete Docker app workloads.
- Rename or relocate the Manifest Docker app concept so it reads as an app workload, not the Docker runtime itself.
- Keep single-GPU VFIO as current-desktop-specific configuration.
- Do not generalize VFIO PCI IDs, VM names, hooks, or host-specific hardware unless a second real host needs it.
- Treat host files as adapters that select shared profiles and provide host-specific values.
- Favor deep modules: small host-facing interfaces with real behavior behind them.
- Avoid new abstractions that only move imports around without improving locality or leverage.
- Preserve current desktop behavior while moving structure.

## Testing Decisions

- Good tests should evaluate external behavior: host configurations build, profiles can be selected or omitted, and expected packages/options appear in evaluated configs.
- Do not test implementation details such as exact internal import order unless ordering is externally meaningful.
- Test the host registry by evaluating every declared NixOS configuration.
- Test the shared system base by evaluating at least the desktop configuration after extraction.
- Test the shared home profile by evaluating Home Manager through the system toplevel build.
- Test the desktop profile by confirming desktop hosts include GUI/session behavior and server-style hosts can omit it.
- Test Docker separation by confirming Docker runtime and Manifest workload evaluation remain intact.
- Test VFIO only through the current desktop host evaluation, because VFIO is explicitly not a reusable multi-host profile yet.
- Prior art: use the repo's known integrated build target for the desktop system toplevel as the first verification path.

## Out of Scope

- Making the single-GPU VFIO setup generic across hosts.
- Adding the actual laptop host hardware configuration.
- Adding the actual home server host hardware configuration.
- Changing the current desktop's intended runtime behavior.
- Replacing Home Manager, nixCats, Codex wiring, GitNexus wiring, or existing Neovim plugin management.
- Introducing a new secret-management system.
- Reworking application configs outside what is needed to clarify module/profile ownership.

## Further Notes

GitNexus was available but its index was one commit behind and had no execution flows for this repo. A refresh attempt timed out, so the architecture plan should be verified with normal Nix evaluation and, when possible, a fresh GitNexus index before broad implementation.

This PRD intentionally keeps the repo learning-friendly: the desired result is not maximum abstraction, but a clearer shape where shared base, desktop profile, app workloads, and host-local machine details are easy to distinguish.

# Workstation security remediation 22 October 2026

**Nix rollback:** The user canceled the rebuild and requested restoration of the prior Nix configuration. The NixOS/Home Manager pins, security overlays, compatibility edits, Sanity dependency changes, and subsequent Signal packaging change were restored from the pre-security snapshot. The canceled update was never activated; generation 284 remains the active and default boot system. The prepared-system sections below are historical, not the current checkout state. Separate container and MCP bridge changes described below were not reverted by this Nix rollback.

PostgreSQL and Redis have been replaced with patched images and are healthy. The MCP bridge's installed dependencies have been refreshed. A NixOS and Home Manager update is prepared and evaluates successfully, but **has not been built or activated**. The running kernel remains **6.18.35** and the active system remains the June 16 generation. The urgent kernel and Nix daemon findings therefore remain open on the running host.

The follow-up OSV scan checked **879 public npm package/version pairs** in the same four repository lockfiles. It found **one remaining advisory**, down from 59: `braces` 3.0.3, for which no patched release is published. Application-bundled runtimes and dependencies imported by independent flakes also require follow-up; this is not an all-clear for the machine.

The original evidence and advisory links are preserved in [the machine audit](security-machine-audit-2026-10-22.md), [disclosure research](security-disclosures-research-2026-10-22.md), and [dependency audit](security-dependency-audit-2026-10-22.md). Those documents describe the pre-remediation snapshot.

## Changes already applied

| Component | Previous state | Verified current state |
|---|---|---|
| `osthaven-postgres` | PostgreSQL 18.2 | PostgreSQL **18.6**, healthy |
| `osthaven-redis` | Redis 7.4.9 | Redis **7.4.11**, healthy |
| Pi MCP bridge dependencies | SDK 1.29.0 and affected transitive dependencies | SDK **1.32.1** installed; npm audit reports **zero** findings; client and stdio transport imports pass |

The databases retain their existing named volumes, Docker network and loopback-only port bindings (`127.0.0.1:5432` and `127.0.0.1:6379`). Resolved container environment settings matched the previous containers before replacement. The only changes to [the Osthaven Compose file](/home/pablo/projects/osthaven/docker/docker-compose.yml) are its image references:

- `postgres:18.6@sha256:edb0c08dc33befd0262ab3b5cf1c4f3f8cfd8b09e88c05b45adee29d6761ddb6`
- `redis:7.4.11-alpine@sha256:892022f9f18c26c92c30e15194d132f90044af87b94a491a75429bbc3982eab1`

Before replacement, `pg_dumpall` and Redis `SAVE` produced backups in `/home/pablo/.local/state/security-remediation/2026-10-22/`: `postgres.sql` (378,341 bytes) and `redis.rdb` (903 bytes). The directory has mode 0700 and the files have mode 0600. Backup restoration has not been tested. Keep these backups until application behavior and data have been verified.

Compose configuration validation, image version checks, container replacement with `--no-build`, health checks and volume/binding verification passed. Existing Pi processes may retain already-loaded modules; restart the relevant Pi session to load the refreshed bridge dependencies.

## Prepared system update

[flake.lock](/home/pablo/nix-dot/flake.lock) now selects Nixpkgs commit `76986a7b1a34a995c9860dfaf233322da85d3ff1` from October 22 and Home Manager commit `cb7de2c7e589afe7531d4832c71ad4df144624ea`. The Nixpkgs lock is ahead of the channel snapshot checked during remediation. The input still tracks `nixos-unstable`; version assertions guard the selected packages against regressions when that lock is refreshed.

[The security overlay](/home/pablo/nix-dot/overlays/security-2026-10.nix) supplies fixes missing from that Nixpkgs tree. [The security module](/home/pablo/nix-dot/modules/system/security-updates.nix) installs the overlay and checks key versions. Evaluation resolves these targets:

| Component | Prepared version |
|---|---|
| Kernel | **6.18.58** |
| Nix daemon | **2.34.9** |
| Node branches 22, 24, 26 | **22.23.4 / 24.22.1 / 26.12.1** |
| Shared Brotli | **1.2.1** |
| curl | **8.23.0** |
| OpenSSL | **3.5.9** |
| NSS and CA bundle | **3.131.1** |
| Chrome and Chromium | **156.0.8078.47** |
| Firefox | **158.0.1** |
| WebKitGTK | **2.54.1** |
| XWayland | **24.1.14** |
| libX11, libXi, libXpm, libXrender, libXtst | **1.8.14 / 1.8.4 / 3.5.20 / 0.9.13 / 1.2.6** |
| OpenSSH | **10.6p1** |
| NVIDIA stable driver | **595.104.02** |
| QtBase | **6.12.0** |
| Docker, containerd, runc | **29.9.1 / 2.4.1 / 1.5.2** |

Node 22 and 26 deliberately retain Nixpkgs' Brotli 1.2.0 **with its decoder security backport**. Feeding Brotli 1.2.1 into that builder would apply the same decoder change twice. Node 24 uses the updated 1.2.1 library. A version string alone will not distinguish these patched 1.2.0 copies from unpatched copies.

Additional configuration changes:

- SSH is prepared for public-key authentication, disabling password and keyboard-interactive authentication. The existing authorized key remains configured. This change takes effect only after activation.
- Persistent journaling uses the new `services.journald.settings.Journal.Storage` option.
- The removed `boot.initrd.verbose` option is gone; the existing quiet-boot kernel parameters remain.
- Handy's bun2nix dependency evaluates Linux systems only, avoiding an obsolete Intel macOS formatter target that prevented evaluation with the newer Nixpkgs.

Pre-existing repository changes, including the user's application version updates, remain intact. Building the flake will include that working tree as well as these remediation changes.

## Dependency updates and checks

The bridge's refreshed transitive versions include Hono 4.13.13, proxy-addr 2.0.8, fast-uri 3.1.9, qs 6.16.1, body-parser 2.4.0 and ip-address 10.7.4. `npm ci --ignore-scripts` installed the bridge dependencies without running lifecycle scripts.

The Sanity 8.22.0 version already present in the working tree was preserved. Its lockfile now resolves js-yaml 4.3.2, smol-toml 1.9.1 and the affected typeid-js dependency to uuid 11.1.1. Removing the old YAML dependency also removes the vulnerable sprintf-js dependency path.

The upstream `@vercel/frameworks` code calls `safeLoad`, which throws under js-yaml 4. [A packaging patch](/home/pablo/nix-dot/patches/vercel-frameworks-js-yaml-4.patch) changes this call to js-yaml 4's safe `load` API. [Compatibility checks](/home/pablo/nix-dot/tools/test_sanity_security_overrides.cjs) passed against an isolated installation of the exact affected dependency versions: YAML, TOML and JSON configuration parsing, rejection of an unsafe YAML tag, missing-file behavior, and TypeID/UUID generation. The Nix package applies the patch and runs these checks before installation. The new Sanity package itself is not installed yet.

| Repository npm tree | Follow-up npm audit |
|---|---|
| MCP bridge | 0 |
| Pi wrapper | 0 |
| Codex ACP wrapper | 0 |
| Sanity wrapper | 7 high dependency paths, all caused by the single `braces` advisory |

The independent OSV rescan returned only `GHSA-vfj7-8cjw-p6xm` for `braces` 3.0.3. This measures the four checked lockfiles, not every installed application or source checkout.

## Remaining gaps

1. **The system fixes are not active.** Building and activating the prepared generation is required to replace the Nix daemon and system packages. A subsequent reboot is required for the kernel and loaded NVIDIA driver. Long-running applications must also restart to use new libraries.
2. **Codex bundles older runtimes.** The previously observed Node 24.21.0 desktop sidecar and Node 24.19.0 artifact runtime are below the October security release. The existing Swamp package-update check reports the packaged Codex 26.1016.61520 and Hermes 0.22.4 as current upstream. No supported newer package was available through that check. System Node updates do not replace these embedded copies. They were not overwritten with unverified binaries. [Node security release](https://nodejs.org/en/blog/vulnerability/october-2026-security-releases).
3. **Independent flake packages do not automatically inherit the system overlay.** The prepared derivation graph still includes Node 24.21.0, libXtst 1.2.5, NSS 3.112.5, curl 8.22.0 and unpatched Brotli 1.2.0 from separate package sets. Direct consumers include Codex packaging and Handy for libXtst. Some references are build tools or fetchers; derivation dependencies do not prove runtime reachability. These require upstream package-set integration and inspection of the realized runtime closure before an all-clear. The version table above describes the system package set, not every dependency of every application.
4. **`braces` has no published patched version.** The advisory concerns processing attacker-controlled, deeply nested glob patterns. Its maintainer disputes treating arbitrary untrusted patterns as safe input and discusses input limits. No remote input path was established for this local Sanity CLI installation. Keep untrusted glob patterns out of these commands; the advisory remains recorded, not suppressed or claimed fixed. [Advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm), [maintainer discussion](https://github.com/micromatch/braces/issues/70).

## Validation and activation gate

Full NixOS/Home Manager evaluation passed with `--option allow-import-from-derivation false --no-write-lock-file`, producing:

`/nix/store/gcg9299cvky1kwz6x0nqqg5j4k8yn7zh-nixos-system-nixos-pablo-26.11.20261022.76986a7.drv`

Upstream source downloads were hash-verified. The inherited Node 24 source patches and Brotli platform patch pass dry-run application against the updated sources. The changed source passes `git diff --check`. Evaluation still emits non-blocking upstream/configuration deprecation warnings. Compilation, boot, full desktop operation and post-activation runtime checks remain unverified.

[AGENTS.md](/home/pablo/nix-dot/AGENTS.md:56) explicitly says: “Requests to update versions, edit configuration, or implement changes are NOT permission to build.” Consequently no `nix build`, `nixos-rebuild`, package compilation, activation or reboot was performed. Explicit authorization to build and activate is the next required step. A reboot should be coordinated after activation, followed by checks of the booted kernel, running Nix daemon executable, driver, browser/runtime versions and the actual application dependency closures.

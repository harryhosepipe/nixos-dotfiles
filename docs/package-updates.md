# Swamp package updates

The `nix-package-updates` workflow checks the configuration in this checkout.
Update mode edits package files directly in this checkout. It never builds packages,
activates a configuration, launches applications, pushes branches, or opens PRs.

## Packages and release sources

| Package ID | Release policy | Files changed by an update |
| --- | --- | --- |
| `codex-desktop` | Latest commit of the existing `ilysenko/codex-desktop-linux` input; app version comes from its Linux package pins | `flake.lock` |
| `hermes-desktop` | Stable `NousResearch/hermes-agent` release; preserves the desktop wrapper | `flake.nix`, `flake.lock`, `modules/home/hermes.nix` |
| `pi` | npm `@earendil-works/pi-coding-agent` `latest` | npm manifest and lock, Pi version and dependency hash |
| `t3code` | Latest published nightly with an x86_64 AppImage | T3 version and source hash in `packages/default.nix` |
| `dokploy-cli` | Stable `Dokploy/cli` release | Version, source hash, and pnpm dependency hash in `packages/default.nix` |
| `vercel-cli` | npm `@vercel/vc-native-linux-x64` `latest` | Version and source hash in `packages/vercel-cli.nix` |
| `sanity-cli` | npm `@sanity/cli` `latest` | npm manifest and lock, version in `packages/default.nix` |

The Codex wrapper revision can change even when its bundled app version stays
the same. Hermes follows the agent release tag because its Nix desktop package
is derived from that source. Stable adapters refuse prereleases; T3 explicitly
keeps its nightly channel. Versions ahead of the release source are reported
without downgrading.

## Run

Swamp must be on PATH and signed in (`swamp auth login`). This repository is
already initialized for Codex. The behavior is local to the repo; no extension
publication or scheduler is required.

```sh
cd /home/pablo/nix-dot
swamp workflow validate nix-package-updates
swamp workflow run nix-package-updates
swamp workflow run nix-package-updates --input mode=check --input packages=pi,t3code
```

Check mode is the default and does not edit package definitions, lockfiles,
or Git branches. Swamp saves its usual run history under the ignored `.swamp/`.

To check and update packages together:

```sh
swamp workflow run nix-package-updates --input mode=update
```

Optional `packages` uses the IDs above, separated by commas, or `all`.
Update mode writes versions, hashes, and lockfiles into your current checkout
and leaves your current branch selected. After a successful run, your only
follow-up command is `nrs` to rebuild and activate as usual. No branch switch,
merge, or commit is required by the workflow.

Existing edits are allowed and preserved; adapters stop if the packaging no
longer matches the expected structure. The updater takes a lock and stops if
files change during the release check. Avoid editing package files while an
update is running. Per-package edits are sequential, and an unsuccessful
package update restores that package's prior files while preserving earlier
successful updates and pre-existing edits. Repeating a run reads the versions
currently in your checkout, skips packages already current, and retries the
configuration check even when no new releases are available.

## Results

Every package records its configured version, candidate version, release source,
channel, status, and changed files. Statuses are `up-to-date`, `available`,
`ahead-of-upstream`, `updated`, and `failed`. Network errors are failures, not
"no update" results. A failing package or configuration check makes the Swamp
run fail after retaining the structured result.

The workflow prints a package table after each run, including configured and
available versions and a readable status. Update-mode reports also include the
current branch, checkout directory, changed files, and evaluation results. The
same summary remains available afterwards:

```sh
swamp report get @pablo/package-update-summary --workflow nix-package-updates
```

```sh
swamp data query 'behavior("nix-package-updates") && name == "package-updates"' --select content
swamp workflow history search --json
```

The behavior delegates to `tools/package_updates.py`, which also has a direct
CLI for troubleshooting:

```sh
python3 tools/package_updates.py --mode check --packages all
python3 -m unittest discover -s tools -p 'test_package_updates.py'
~/.swamp/deno/deno test extensions/reports/package_updates_test.ts
```

## Validation and dependency downloads

Updates preserve launcher code, native Wayland settings, and application
patches. New Nix code must parse and pass `git diff --check`. The full NixOS
activation derivation is evaluated with import-from-derivation disabled and
lockfile writing disabled. These are evaluation checks, not build or runtime
tests. Reports explicitly retain `built: false` and `activated: false`.

Pi's dependencies are fetched with `prefetch-npm-deps` using fetcher version 2.
Dokploy's dependencies are downloaded with the pinned Nixpkgs `pnpm_10`, with
lifecycle scripts disabled, then normalized and hashed to match the pinned
`fetchPnpmDeps` version 3 format. No Nix fetcher derivation is built. A change
to Dokploy's fetcher settings or pnpm hooks stops the adapter for review.
Sanity uses its existing `importNpmLock` setup. Missing registry integrity
entries are filled only after confirming the registry's tarball URL matches.

Update-only helper tools are resolved from the existing locked Nixpkgs. If a
tool is absent from the local store, the update is reported as failed; the
workflow never builds or installs it implicitly. Large dependency downloads
and AppImage downloads can make update mode slower than check mode.

Builds, activation, and desktop runtime checks remain separate tasks requiring
an explicit request under `AGENTS.md`. In particular, successful evaluation
does not prove a desktop app launches or still uses native Wayland.

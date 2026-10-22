# Buzz Desktop 0.5.8 + Codex ACP on NixOS

Research date: 2026-08-09

## Conclusion

The working combination for Buzz Desktop 0.5.8 is:

- Buzz release/tag `desktop-v0.5.8`.
- A `codex` CLI visible to the Buzz GUI process and authenticated in the same `HOME` / `CODEX_HOME` that Buzz inherits.
- `@agentclientprotocol/codex-acp` **1.1.7 or newer**; pinning **1.1.14** is the current verified choice.
- Node.js on the adapter's runtime `PATH` (`codex-acp` is a `#!/usr/bin/env node` program).
- `xdg-open` on Linux so ChatGPT login can open the browser.

Do **not** install or package `@zed-industries/codex-acp` 0.16.x for Buzz 0.5.8. Buzz deliberately classifies that implementation as outdated and, in its own installer, removes it before installing `@agentclientprotocol/codex-acp`. The old repository likewise says development moved to the Agent Client Protocol organization and directs new installs to the new package. Sources: [Buzz runtime/version gate](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/managed_agents/discovery.rs#L148-L179), [minimum 1.1.7 and old-adapter detection](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/managed_agents/discovery.rs#L1146-L1289), [Buzz reinstall plan](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/commands/agent_discovery.rs#L24-L56), and [Zed adapter migration notice](https://github.com/zed-industries/codex-acp/tree/v0.16.0#readme).

## Exact versions and executables

Buzz's Codex catalog requires both:

1. `codex-acp`, the ACP server that Buzz talks to over stdio.
2. `codex`, the external CLI used by Buzz's availability and login-status probe.

Buzz's compiled-in install command is `npm install -g @agentclientprotocol/codex-acp`, and its login probe is exactly `codex login status`. It reads Codex configuration from `~/.codex/config.toml`. [Buzz Codex catalog](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/managed_agents/discovery.rs#L148-L179)

`@agentclientprotocol/codex-acp` 1.1.14 was published on 2026-08-07, one day before Buzz Desktop 0.5.8. It exposes the `codex-acp` executable and declares `@openai/codex ^0.147.0`; the lockfile resolves the compatible native Codex package. [Adapter release](https://github.com/agentclientprotocol/codex-acp/releases/tag/v1.1.14), [package manifest](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/package.json#L1-L72), and [installation documentation](https://github.com/agentclientprotocol/codex-acp/tree/v1.1.14#installation).

The adapter normally starts the Codex App Server from its bundled `@openai/codex` dependency. `CODEX_PATH` overrides that behavior. Leave `CODEX_PATH` unset unless the selected external Codex build has been validated against the adapter, because a dead or incompatible App Server can strand in-flight ACP requests. [Codex process launch](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/src/CodexCli.ts#L1-L32) and [open hang fix](https://github.com/agentclientprotocol/codex-acp/pull/359).

Runtime dependency summary:

| Component | Required at runtime | Reason |
| --- | --- | --- |
| Buzz | Existing AppImage wrapper dependencies | GTK/WebKit/GStreamer side of the desktop app |
| `codex-acp` 1.1.14 | Node.js; its installed npm dependency closure | Entrypoint is `#!/usr/bin/env node`; adapter and Codex package dependencies are bundled by npm |
| Bundled Codex | Its platform npm package | `@openai/codex` supplies an x86_64 Linux musl/static native binary, so it does not need the generic glibc loader on NixOS |
| Browser login | `xdg-open` (normally from `xdg-utils`) | The adapter uses the Node `open` package for the ChatGPT authorization URL |
| Buzz readiness | A separate `codex` executable | Buzz will report CLI missing/logged out even though the adapter bundles Codex internally |

## Authentication flow

Official Codex supports ChatGPT subscription login and API-key login. `codex login` starts the browser flow; `printenv OPENAI_API_KEY | codex login --with-api-key` stores API-key authentication. [Official OpenAI authentication documentation](https://learn.chatgpt.com/docs/auth)

For Buzz onboarding, the relevant path is ChatGPT login:

1. Buzz resolves `codex-acp` and invokes its bundled `buzz-acp auth-methods --json` helper with `BUZZ_ACP_AGENT_COMMAND=<absolute codex-acp path>`.
2. `codex-acp` initializes and advertises API-key and ChatGPT methods. ChatGPT is a normal ACP authentication method, not a terminal method.
3. Buzz deliberately filters API-key methods from the Codex onboarding card and selects the first remaining method, ChatGPT.
4. `codex-acp` asks the Codex App Server for an authorization URL, calls the browser opener, and waits for the App Server's `account/login/completed` notification.
5. After the connect operation succeeds, Buzz independently reruns `codex login status` to decide whether the runtime is ready.

Sources: [Buzz auth helper invocation](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/commands/agent_auth.rs#L110-L202), [adapter auth methods](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/src/CodexAuthMethod.ts#L17-L84), [Buzz Codex method filter](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src/features/onboarding/ui/SetupStep.tsx#L397-L441), and [adapter ChatGPT browser/login completion flow](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/src/CodexAcpClient.ts#L131-L199).

Credential identity is critical. Codex normally stores credentials below `CODEX_HOME` (default `~/.codex`; file-store credentials are in `auth.json`, while configuration can select an OS credential store). The adapter inherits its process environment, while Buzz separately spawns an external `codex login status`. Those processes must receive the same `HOME` and `CODEX_HOME`. [Official credential-storage documentation](https://developers.openai.com/codex/auth#credential-storage)

### Terminal requirements

The current Codex adapter does **not** require a terminal emulator for ChatGPT authentication. It does not mark ChatGPT auth as `type: terminal`; it opens a browser itself.

Buzz's Linux terminal search (`x-terminal-emulator`, `gnome-terminal`, `konsole`, then `xterm`) only applies when an adapter explicitly advertises terminal authentication metadata. Therefore Ghostty compatibility is not the blocker for `@agentclientprotocol/codex-acp` 1.1.14. [Buzz terminal-auth dispatch](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/commands/agent_auth.rs#L249-L414) and [ACP terminal authentication contract](https://agentclientprotocol.com/protocol/authentication).

## Why the UI can say `CHECKING…` for ages

The label has a precise implementation. After the connect mutation reports success, Buzz refetches runtime discovery every two seconds. It stops when the runtime is ready or after 120 seconds. [Buzz onboarding polling loop](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src/features/onboarding/ui/SetupStep.tsx#L113-L139)

Buzz's lower-level limits are:

- `codex login status` discovery probe: 10 seconds.
- `buzz-acp auth-methods` initialization: 10 seconds.
- interactive `buzz-acp authenticate`: 10 minutes.
- model initialization plus `session/new`: 10 seconds.

[Discovery timeout](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/managed_agents/discovery.rs#L1002-L1070) and [helper timeout constants and use](https://github.com/block/buzz/blob/desktop-v0.5.8/crates/buzz-acp/src/lib.rs#L62-L67).

Known causes, in diagnosis order:

1. **Wrong adapter generation.** `@zed-industries/codex-acp` 0.16.x, any unparseable `--version`, or a new-package version below 1.1.7 is `adapter_outdated`.
2. **GUI `PATH` mismatch.** The interactive shell sees `codex`, `codex-acp`, or `node`, but the desktop process cannot resolve the same executable. Put all three in a declarative Home Manager/system profile and prefix them into the Buzz wrapper's `PATH`.
3. **Credential-home mismatch.** The adapter/browser flow writes authentication under one `HOME`/`CODEX_HOME`, but Buzz's external `codex login status` reads another. This exactly produces successful login followed by the two-minute `CHECKING…` loop.
4. **Invalid Codex config.** Buzz has a distinct `config_invalid` result when the CLI reports a configuration parse error. Run the exact probe in the same environment as Buzz and inspect stderr.
5. **Browser opener unavailable.** Without a usable `xdg-open`, the adapter cannot launch the ChatGPT authorization URL.
6. **App Server death.** An upstream open issue/PR documents that a dead spawned Codex App Server can leave adapter requests unresolved while the ACP connection remains open; Buzz's outer interactive timeout then makes this look like a ten-minute hang. Prefer the bundled Codex and do not set an unvalidated `CODEX_PATH`. [Adapter PR #359](https://github.com/agentclientprotocol/codex-acp/pull/359)
7. **API-key-only environment.** Buzz 0.5.8's onboarding readiness is based on stored CLI status, and its UI filters API-key methods from the Codex card. An environment variable alone is not a substitute for making `codex login status` exit zero. [Buzz issue documenting the status-gate mismatch](https://github.com/block/buzz/issues/4755)
8. **Polling starvation from interactive shell initialization.** Buzz refetches the entire runtime catalog every two seconds while the button says `CHECKING…`. Resolving each absent runtime can invoke `bash -l`, and this machine's `.bash_profile` sourced interactive `.bashrc` setup (`oh-my-posh`, fzf, and zoxide) for every probe. A traced refresh took longer than the poll interval, causing overlapping/cancelled refreshes. Guard `.bashrc` with `[[ $- == *i* ]]` in `.bash_profile`.

On this NixOS host, tracing the GUI also showed the real Codex readiness child exiting 1 even though ACP initialization and model discovery succeeded against the same stored credentials. The deployed workaround adds a `codex` shim only inside Buzz's FHS environment: `codex login status` returns success when `$CODEX_HOME/auth.json` exists, while every other invocation delegates to the real Home Manager Codex CLI. This keeps the workaround out of the user's normal shell and leaves actual ACP authentication as the functional check.

Buzz has an upstream end-to-end confirmation that a current adapter can reuse stored `~/.codex/auth.json` without an API-key environment variable. [Buzz PR #4623](https://github.com/block/buzz/pull/4623)

## Model discovery

ACP model discovery is session-scoped. During `session/new`, an agent can return stable `configOptions`; a model selector has `category: "model"`, its current value, and available options. [ACP Session Config Options](https://agentclientprotocol.com/protocol/session-config-options)

`codex-acp` asks the Codex App Server for models and turns them into ACP model/reasoning configuration options. [Model option creation](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/src/ModelConfigOption.ts) and [session model response](https://github.com/agentclientprotocol/codex-acp/blob/v1.1.14/src/CodexAcpServer.ts#L1216-L1245).

Buzz's generic model helper performs `initialize` followed by `session/new`, prefers stable `configOptions`, falls back to legacy `availableModels`, and exposes this as `buzz-acp models --json`. [Buzz model helper](https://github.com/block/buzz/blob/desktop-v0.5.8/crates/buzz-acp/src/lib.rs#L4373-L4505) and [desktop normalization](https://github.com/block/buzz/blob/desktop-v0.5.8/desktop/src-tauri/src/commands/agent_models.rs#L942-L1016).

Buzz 0.5.8's static Codex catalog still says `supports_acp_model_switching: false`. That flag should not be mistaken for the adapter lacking model data: the generic helper can discover it, but the desktop may decline to persist a model override through its static Codex configuration path. The Codex App Server remains authoritative for the models available to the signed-in account.

## Recommended Nix packaging

Package the new adapter from its tagged source with its lockfile. This exact expression was built successfully on this NixOS configuration and produced `@agentclientprotocol/codex-acp 1.1.14`:

```nix
codex-acp = pkgs.buildNpmPackage rec {
  pname = "codex-acp";
  version = "1.1.14";

  src = pkgs.fetchFromGitHub {
    owner = "agentclientprotocol";
    repo = "codex-acp";
    rev = "v${version}";
    hash = "sha256-Mz4kxOvJPDp7R2H2wwTkPuuAICUJXxHdyFvtphOfD/M=";
  };

  npmDepsHash = "sha256-oST6ENGfWoa65Ts3RrmHUm5G+OgTQ/StptbnQzlJN/E=";
};
```

Then ensure the user's effective package set includes:

```nix
home.packages = with pkgs; [
  codex                 # the existing declarative Codex CLI package
  codex-acp             # package above
  nodejs_22             # adapter shebang/runtime
  xdg-utils             # xdg-open for ChatGPT browser login
];
```

Wrap Buzz with a deterministic child-process path rather than relying on the display manager's environment:

```nix
wrapProgram $out/bin/buzz \
  --prefix PATH : ${pkgs.lib.makeBinPath [
    codex
    codex-acp
    pkgs.nodejs_22
    pkgs.xdg-utils
  ]}
```

Important rules for the wrapper:

- Do not overwrite `HOME`.
- Either leave `CODEX_HOME` unset everywhere (therefore `~/.codex`) or set the same absolute value for Buzz, `codex`, and `codex-acp`.
- Leave `CODEX_PATH` unset so adapter 1.1.14 uses its compatible bundled Codex unless there is a specific, tested reason to override it.
- Expose Buzz's bundled `buzz-acp` sidecar as an executable or retain its absolute path for diagnostics; it is the component that performs auth and model helper probes.
- Never let a mutable `~/.local/bin/codex-acp` or old npm-global shim precede the Nix package on Buzz's `PATH`.

## Verification sequence

Run these after `nixos-rebuild switch` / Home Manager activation, from a fresh login session:

```bash
command -v buzz codex codex-acp node xdg-open

codex-acp --version
# Expected shape and minimum: @agentclientprotocol/codex-acp 1.1.14

codex login status
printf 'codex login status exit=%s\n' "$?"
# Must be exit 0 before Buzz can mark Codex ready.
```

Check the exact credential environment without printing secrets:

```bash
printf 'HOME=%s\nCODEX_HOME=%s\n' "$HOME" "${CODEX_HOME:-$HOME/.codex}"
test -r "${CODEX_HOME:-$HOME/.codex}/config.toml" && echo 'config readable'
```

If the packaged Buzz sidecar is on `PATH`:

```bash
BUZZ_ACP_AGENT_COMMAND="$(command -v codex-acp)" \
BUZZ_ACP_AGENT_ARGS='' \
timeout 15s buzz-acp auth-methods --json

BUZZ_ACP_AGENT_COMMAND="$(command -v codex-acp)" \
BUZZ_ACP_AGENT_ARGS='' \
timeout 15s buzz-acp models --json
```

Expected auth output contains a ChatGPT method. Expected model output identifies `@agentclientprotocol/codex-acp` and returns model entries when the account/App Server makes them available.

Finally, launch Buzz from the desktop entry, not the shell, and verify the GUI environment resolves the same programs. If it remains on `CHECKING…`, reproduce the wrapper environment with an explicit minimal `PATH` and run `codex login status`; the failure is in that exact probe, not in a missing terminal emulator.

# Logging in through the custom Figma Linux wrapper

Research date: 2026-08-17

## Short answer

The wrapper supports the same three account methods exposed by Figma: email and password, Google SSO, and SAML SSO. Email/password can complete inside the app. Google and SAML deliberately move to the system browser and must return to the desktop app through a `figma://` URL. Figma documents that browser handoff and return behavior in its [login guide](https://help.figma.com/hc/en-us/articles/360041064554-Log-in-or-add-accounts).

On this machine, the browser-return association is installed correctly:

```text
$ xdg-mime query default x-scheme-handler/figma
io.github.nickvdp.figma-desktop-linux.desktop
```

The failure was later in the flow. The local launcher log recorded repeated `figma://app_auth/redeem?...` launches, but the running app returned to `/login`. The log also reported Chromium's process-singleton handoff error while Figma remained alive without a visible window. This fits the Linux/Electron deep-link design: when the app is already running, a browser callback starts a second instance and the primary instance must receive its command line through Electron's `second-instance` mechanism. Electron documents that exact Linux flow in its [deep-link guide](https://www.electronjs.org/docs/latest/tutorial/launch-app-from-url-in-another-app).

There is also an unresolved upstream report with the same user-visible loop: browser authentication completes, the windows close, Figma reopens, and the login button remains. It is still open and has no maintainer response: [IliyaBrook/figma-linux issue #16](https://github.com/IliyaBrook/figma-linux/issues/16).

## Recommended login sequence

After activating the patched package, use the normal Figma flow:

1. If the account supports it, choose email/password in Figma. This avoids the external-browser callback entirely.
2. For Google or SAML, open Figma and start **Log in with browser**.
3. Complete authentication in the browser and accept the prompt to open Figma. The patched running instance receives the `figma://` callback normally.

Before a retry, confirm there is no old Figma process:

```sh
pgrep -af 'figma-desktop|figma-linux|electron.*app\.asar'
```

Then verify the protocol handler:

```sh
xdg-mime query default x-scheme-handler/figma
```

For this Nix package, the expected result is:

```text
io.github.nickvdp.figma-desktop-linux.desktop
```

## What the wrapper is doing

The package in [`packages/default.nix`](../packages/default.nix) is not a browser-only web wrapper. It packages `IliyaBrook/figma-linux`, which extracts and patches the official Windows Electron application. Upstream describes the patched client and its `figma://` support in the [project README](https://github.com/IliyaBrook/figma-linux/tree/126.5.6#readme).

The local Nix wrapper:

- enables native Wayland with `FIGMA_USE_WAYLAND=1`;
- redirects `XDG_DATA_HOME` to `~/.cache/figma-desktop-linux/xdg-data` so the AppImage's self-integration files do not pollute the normal user data directory;
- installs a normal desktop entry with `MimeType=x-scheme-handler/figma` and `Exec=figma-desktop %u`;
- keeps Electron's actual session and web state under `~/.config/figma-linux`, with Figma desktop-profile state under `~/.config/Figma`.

The effective protocol default currently points to the Nix-installed desktop entry, not the extra AppImage desktop entry placed below the redirected XDG data directory. The handler-registration layer therefore appears healthy.

Upstream has already fixed three earlier authentication failures: Electron-version mismatch, a broken preload bridge when Chromium sandboxing is enabled, and missing `figma://` registration. The details are in the upstream [authentication-fix commit](https://github.com/IliyaBrook/figma-linux/commit/157132cde85813b8f8bbd87c9a65679976c11a65). An earlier patch also changed Figma's command-line parser to locate the callback URL among Linux Electron arguments: [auth-callback fix](https://github.com/IliyaBrook/figma-linux/commit/97a54a0d9c3ab8e63dcf1740c6b8b6c9f6cd3a82).

## Implemented fix

The package now patches Figma's packed Electron `main.js` during AppImage extraction:

- it calls `requestSingleInstanceLock()` without serializing `process.argv` as `additionalData`;
- when `additionalData` is absent, the `second-instance` handler passes Electron's normal `commandLine` array to Figma's existing `handleCommandLineArgs` implementation;
- it disables the AppImage's self-registration step so that it cannot replace the stable Nix desktop entry with a private cached desktop entry.

`substituteInPlace --replace-fail` makes future upstream drift fail the Nix build instead of silently producing an unpatched package.

The patched package and complete NixOS configuration build successfully. A runtime test started the patched app, invoked the same executable a second time with a synthetic `figma://` URL, and confirmed that the second process exited normally without either the Chromium ProcessSingleton error or Figma's additional-data parse error.

## Version findings

The package remains on Figma `126.5.6`.

Downgrading is not a guaranteed authentication fix:

- both `figma-desktop-126.4.11` and `126.5.6` point to the same upstream source commit (`c38615156b9eaea39336bfb53f8b5b0ef4e5e610`);
- both tags contain the authentication and Linux-argv fixes linked above;
- the downgrade changes the bundled Figma application payload, not the wrapper's deep-link implementation.

The relevant releases are [126.4.11](https://github.com/IliyaBrook/figma-linux/releases/tag/figma-desktop-126.4.11) and [126.5.6](https://github.com/IliyaBrook/figma-linux/releases/tag/126.5.6).

## If it still loops

Do not share `~/.cache/figma-desktop-linux/launcher.log` verbatim. The upstream launcher logs its complete command line, and browser-return command lines include the authentication redemption secret.

Safe checks are:

```sh
xdg-mime query default x-scheme-handler/figma
pgrep -af 'figma-desktop|figma-linux|electron.*app\.asar'
```

Deleting `~/.config/figma-linux` should not be the first response: it destroys cookies, IndexedDB, local/session storage, and caches, while upstream issue #16 provides no evidence that clearing those directories resolves the loop.

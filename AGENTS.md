# Agent Behavior

- NEVER build anything unless the user explicitly asks for a build. Requests to
  update versions, edit configuration, or implement changes are NOT permission
  to build. Do not run `nix build`, `nixos-rebuild`, package compilation, or
  background validation builds without an explicit request. Do not run Nix
  evaluation that can trigger builds through import-from-derivation unless
  builds are explicitly authorized. This rule overrides build/validation
  guidance elsewhere in this file.

- A user question about a file, config, error, or possible change is not permission
  to edit files, run a fix, or proactively solve the issue.
- Diagnose and answer first. Before making any proactive change, ask for explicit
  permission unless the user has already clearly asked for implementation.
- If the user asks "where", "how", "why", "what is wrong", or similar, treat it as
  an explanation request, not an implementation request.

# Linux Desktop Packaging

- This NixOS host uses Hyprland/Wayland. When packaging an AppImage or another
  prebuilt Linux desktop application, inspect its launcher and bundled hooks for
  a forced X11 backend such as `GDK_BACKEND=x11`. Running through XWayland can
  make the interface blurry or pixelated when display scaling is active.
- Prefer the application's supported native-Wayland switch when available (for
  example, CC Switch uses `CC_SWITCH_GDK_BACKEND=wayland`). Apply it in the Nix
  wrapper so launches from both the terminal and the desktop entry behave the
  same. Do not assume every application uses the same environment variable.
- If the bundled hook unconditionally overrides the environment, patch that hook
  during AppImage extraction only after confirming the application works on
  native Wayland. Preserve an X11 fallback when upstream documents unresolved
  Wayland compatibility problems.
- Verify the built package's launcher environment and installed `.desktop`
  `Exec=` target, then test that the full NixOS/Home Manager configuration still
  evaluates.
- After activating a changed wrapper, fully terminate every existing application
  process before testing. Many desktop applications remain in the tray or enforce
  a single instance, so reopening them can focus a stale process that still has
  the old environment. Do not conclude that a wrapper fix failed until a newly
  started process has been tested.
- Verify runtime behavior rather than trusting the package output alone: inspect
  the live process environment for the intended backend variables and use
  `hyprctl clients` to confirm the window is not reported as XWayland. A wrapper
  containing the correct variable is insufficient evidence if the running
  process predates the Home Manager/NixOS activation or an application startup
  hook overwrites it.

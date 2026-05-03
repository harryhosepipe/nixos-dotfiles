# Host Architecture

This repo is organized around declared hosts and reusable profiles.

## Add A Host

1. Add a host entry to `hosts.nix`.

   Each entry should include:

   - `system`: target architecture, such as `"x86_64-linux"`.
   - `user`: the Home Manager user for the host.
   - `hostName`: the real NixOS hostname.
   - `path`: the host folder containing `configuration.nix` and `home.nix`.

2. Create a folder under `hosts/`.

   Host folders should hold machine-specific files:

   - `configuration.nix`: system adapter that selects profiles, hardware, workloads, and host-local files.
   - `home.nix`: Home Manager adapter that selects home profiles.
   - `hardware-configuration.nix`: generated NixOS hardware config.
   - Hardware quirks such as GPU, VFIO, disks, or boot details.

3. Choose system profiles.

   - `modules/system/profiles/shared-base.nix`: shared NixOS defaults for every machine.
   - `modules/system/profiles/desktop-gui.nix`: Hyprland/greetd desktop profile. Omit this for headless server hosts.

4. Choose Home Manager profiles.

   - `modules/home/profiles/shared.nix`: user-wide shell, editor, Git, Codex, dev, and CLI defaults.
   - `modules/home/profiles/desktop-gui.nix`: cursor, GTK/dconf, Firefox, desktop config links, and GUI apps. Omit this for headless server hosts.

5. Choose workloads.

   - `modules/system/docker/runtime.nix`: reusable Docker runtime.
   - `modules/system/app-workloads/manifest.nix`: Manifest app deployment. It imports the Docker runtime itself.

6. Keep host-only config local.

   The current single-GPU VFIO setup is desktop-only. Its PCI IDs, VM names, hooks, and shared directory belong in `hosts/nixos-pablo/vfio.nix`, not in shared profiles.

## Evaluate A Host

Use the host key from `hosts.nix` as the `nixosConfigurations` name:

```sh
nix --extra-experimental-features 'nix-command flakes' build \
  --print-out-paths \
  'path:/home/pablo/nix-dot#nixosConfigurations."desktop".config.system.build.toplevel' \
  --no-link
```

For a future host, replace `"desktop"` with its registry key.

# Dotfiles

This repo builds three NixOS host outputs:

- `desktop`
- `laptop`
- `server`

Hardware config is imported from `/etc/nixos/hardware-configuration.nix`, so builds need `--impure`.

```bash
sudo nixos-rebuild switch --flake /home/pablo/nix-dot#desktop --impure
```

## Fresh install steps

1. Install NixOS and boot into the new system.
2. Make sure the user is named `pablo`.
3. Clone this repo:

```bash
git clone <your-repo-url> /home/pablo/nix-dot
cd /home/pablo/nix-dot
```

4. Generate the machine hardware config in `/etc/nixos`:

```bash
sudo nixos-generate-config
```

5. Build the host you want:

```bash
sudo nixos-rebuild switch --flake /home/pablo/nix-dot#desktop --impure
```

## Where Things Live

- `flake.nix`: host builder and inputs
- `hosts/*/settings.nix`: per-host username, shell, GUI, editor, and feature flags
- `hosts/*/default.nix`: per-host system imports
- `users/pablo/home.nix`: Home Manager entrypoint
- `modules/system`: NixOS modules
- `modules/home`: Home Manager modules
- `config`: live-edit config files symlinked into `$HOME`

# Dotfiles

This repo builds the `desktop` NixOS host.

If you are setting up a fresh machine, the main command to run is:

```bash
sudo nixos-rebuild switch --extra-experimental-features "nix-command flakes" --flake /home/pablo/dotfiles#desktop
```

## Fresh install steps

1. Install NixOS the normal way and boot into the new system.
2. Make sure your user is named `pablo`.
   This repo still assumes the main user is `pablo`, and the home setup points at `/home/pablo/dotfiles`.
3. Clone this repo into your home folder:

```bash
git clone <your-repo-url> /home/pablo/dotfiles
cd /home/pablo/dotfiles
```

4. Replace the old hardware file with one for the new machine:

```bash
sudo nixos-generate-config --show-hardware-config > /home/pablo/dotfiles/hosts/nixos-pablo/hardware-configuration.nix
```

This matters because `hardware-configuration.nix` describes the real disks, boot setup, and file systems for the machine you are on.

5. Build and switch to the `desktop` host:

```bash
sudo nixos-rebuild switch --extra-experimental-features "nix-command flakes" --flake /home/pablo/dotfiles#desktop
```

## Notes

- The flake host name is `desktop`.
- The real network host name for this machine is set in `hosts.nix`.
- After the first successful switch, flakes are enabled by the system config, so future rebuilds can use the shorter command:

```bash
sudo nixos-rebuild switch --flake /home/pablo/dotfiles#desktop
```

## Where things live

- `flake.nix`: the front door for builds
- `hosts.nix`: short list of hosts
- `hosts/nixos-pablo/configuration.nix`: this machine's system config
- `hosts/nixos-pablo/home.nix`: this machine's home-manager config
- `hosts/nixos-pablo/hardware-configuration.nix`: hardware details for this machine only

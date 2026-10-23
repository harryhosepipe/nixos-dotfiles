# DNS Switcher

Click **LAN** (or **WI-FI**) in Waybar to open the panel. You can also search for
**DNS Switcher** in the application launcher.

Choose Pi-hole, Cloudflare, Quad9, or Custom, then press **Use …**. The current
DNS addresses stay visible, and each preset shows whether its primary server
answers a DNS lookup. **Restore defaults** returns control to your normal system
configuration. Escape closes the window; launching again focuses the same app.

Changes affect this computer only, last until reboot, and do not reconnect the
LAN. Pi-hole at `192.168.88.247` remains the declared system default. Public DNS
bypasses Pi-hole filtering and its local hostnames. Apps using their own DNS,
such as browser Secure DNS, may ignore the system setting.

## Implementation

- Native Python/GTK 4 window with Wayland forced in both launchers.
- A named, exclusive `dns-switcher.manual` openresolv entry replaces the active
  DNS list. Removing only that entry restores the existing configuration.
- Only `resolvconf` runs through the host's existing passwordless sudo policy;
  the GUI stays unprivileged. No new sudo or polkit permissions are installed.
- Custom addresses are validated as IPv4/IPv6 literals before privilege
  escalation. Settings are read back after applying; command or verification
  failures attempt to restore the previous override and report rollback errors.
- Health checks query `example.com` directly over UDP to the primary DNS IP,
  with a two-second timeout. They do not depend on working system DNS and do
  not claim that every internet service or secondary resolver is reachable.
- NetworkManager's existing `dns = "none"` and the static Pi-hole configuration
  stay intact. The resolver's existing hook refreshes the nscd cache.

The Home Manager module installs `packages/dns-switcher.nix` on the next normal
activation. For immediate use without a build, this machine's launcher uses
already-installed Python, PyGObject, and GTK libraries registered in
`~/.local/state/dns-switcher/runtime.sh`. It never downloads dependencies during
an outage. The declared package takes precedence once available.

## Verification — 2026-10-22

- Ten tests passed: address validation, real local UDP responses, switching,
  restoration, permission failures, and rollback failures.
- A live switch selected only `1.1.1.1` and `1.0.0.1`; a direct DNS query
  succeeded. Restoration returned exactly `192.168.88.247`, with no remaining
  app override.
- The Waybar launch command opened the panel; invoking it again reused the
  existing window. The active Waybar config and script resolve into this repo.
- Inspected the rendered window at 1.6× display scale. Hyprland reported a
  floating window below the top-right bar with `xwayland = false`; the process
  environment contained `GDK_BACKEND=wayland`.
- Nix syntax parsing, shell syntax, whitespace checks, and Hyprland config
  error checks passed. No Nix builds or full configuration evaluation ran.
- Automated pointer input was unavailable because the desktop portal does not
  provide RemoteDesktop. Visual inspection and the actual launch command were
  verified; the backend switch/restore test ran directly.

Run tests without changing DNS:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools -p test_dns_switcher.py
```

References: [openresolv's exclusive entries and deletion](https://github.com/NetworkConfiguration/openresolv/blob/master/resolvconf.8.in),
[Quad9 service addresses](https://quad9.net/service/service-addresses-and-features/),
[Hyprland window rules](https://wiki.hypr.land/configuring/core/rules/window-rules/).

{
  config,
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  cfg = config.passthrough.singleGpu;
  guestNames =
    if cfg.vmNames != [ ] then
      cfg.vmNames
    else
      [ cfg.vmName ];

  boolToString =
    value:
    if value then
      "1"
    else
      "0";

  hookScript = pkgs.writeShellScript "libvirt-single-gpu-hook" ''
    #!/bin/bash
    set -Eeuo pipefail

    GUEST_NAME="''${1:-}"
    HOOK_PHASE="''${2:-}"
    HOOK_SUBPHASE="''${3:-}"

    TARGET_GUESTS=(${lib.concatMapStringsSep " " lib.escapeShellArg guestNames})
    LOG_FILE="/var/log/libvirt-$GUEST_NAME-hook.log"
    STATE_DIR="/run/libvirt-$GUEST_NAME"
    DM_STATE_FILE="$STATE_DIR/display-manager"
    GPU_VIDEO=${lib.escapeShellArg cfg.gpu.videoPci}
    GPU_AUDIO=${lib.escapeShellArg cfg.gpu.audioPci}
    USB_CONTROLLER=${lib.escapeShellArg cfg.usbControllerPci}
    DM_CANDIDATES=(${lib.concatMapStringsSep " " lib.escapeShellArg cfg.displayManagers})
    RELOAD_NVIDIA=${boolToString cfg.nvidia.enableModuleReload}
    DM=""

    log() {
      local message
      message="$(date '+%Y-%m-%d %H:%M:%S') $*"
      printf '%s\n' "$message" >> "$LOG_FILE"
      sync "$LOG_FILE" || true
      logger -t "libvirt-$GUEST_NAME-hook" -- "$message" || true
    }

    trap 'rc=$?; log "ERROR line $LINENO during $HOOK_PHASE/$HOOK_SUBPHASE: $BASH_COMMAND (rc=$rc)"; exit "$rc"' ERR

    guest_matches() {
      local candidate
      for candidate in "''${TARGET_GUESTS[@]}"; do
        [[ "$GUEST_NAME" == "$candidate" ]] && return 0
      done
      return 1
    }

    stop_display_manager() {
      local dm_link
      dm_link="$(readlink -f /etc/systemd/system/display-manager.service || true)"
      if [[ -n "$dm_link" ]]; then
        DM="$(basename "$dm_link")"
      fi

      if [[ -n "$DM" ]] && systemctl is-active --quiet "$DM"; then
        log "Stopping display manager: $DM"
        printf '%s\n' "$DM" > "$DM_STATE_FILE"
        systemctl stop "$DM"
        return
      fi

      local candidate
      for candidate in "''${DM_CANDIDATES[@]}"; do
        if systemctl is-active --quiet "$candidate"; then
          DM="$candidate"
          log "Stopping display manager: $DM"
          printf '%s\n' "$DM" > "$DM_STATE_FILE"
          systemctl stop "$DM"
          return
        fi
      done
    }

    start_display_manager() {
      if [[ -z "$DM" ]] && [[ -f "$DM_STATE_FILE" ]]; then
        DM="$(cat "$DM_STATE_FILE")"
      fi
      if [[ -n "$DM" ]]; then
        log "Starting display manager: $DM"
        systemctl start "$DM" || true
      fi
    }

    unbind_consoles() {
      local vt
      for vt in /sys/class/vtconsole/vtcon*; do
        [[ -e "$vt/bind" ]] || continue
        echo 0 > "$vt/bind" || true
      done
    }

    rebind_consoles() {
      local vt
      for vt in /sys/class/vtconsole/vtcon*; do
        [[ -e "$vt/bind" ]] || continue
        echo 1 > "$vt/bind" || true
      done
    }

    unbind_efi_framebuffer() {
      if [[ -e "/sys/devices/platform/efi-framebuffer.0/driver/unbind" ]]; then
        echo "efi-framebuffer.0" > /sys/devices/platform/efi-framebuffer.0/driver/unbind || true
      fi
    }

    rebind_efi_framebuffer() {
      if [[ -e "/sys/bus/platform/drivers/efi-framebuffer/bind" ]]; then
        echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind || true
      fi
    }

    unload_nvidia() {
      modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia i2c_nvidia_gpu || true
    }

    load_nvidia() {
      modprobe nvidia || true
      modprobe nvidia_modeset || true
      modprobe nvidia_uvm || true
      modprobe nvidia_drm || true
      modprobe i2c_nvidia_gpu || true
    }

    bind_device_to_vfio() {
      local dev="$1"
      [[ -n "$dev" ]] || return 0
      [[ -e "/sys/bus/pci/devices/$dev" ]] || return 0

      log "Binding $dev to vfio-pci"

      if [[ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]]; then
        if ! echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind"; then
          log "Failed to unbind $dev from current driver"
          return 1
        fi
      fi

      if ! echo "vfio-pci" > "/sys/bus/pci/devices/$dev/driver_override"; then
        log "Failed to set driver_override for $dev"
        return 1
      fi

      if ! echo "$dev" > /sys/bus/pci/drivers_probe; then
        log "Failed to reprobe $dev onto vfio-pci"
        return 1
      fi

      if [[ -L "/sys/bus/pci/devices/$dev/driver" ]]; then
        log "Bound $dev to $(basename "$(readlink -f "/sys/bus/pci/devices/$dev/driver")")"
      else
        log "Failed to bind $dev to vfio-pci"
        return 1
      fi
    }

    reprobe_device() {
      local dev="$1"
      [[ -n "$dev" ]] || return 0
      [[ -e "/sys/bus/pci/devices/$dev" ]] || return 0

      if [[ -e "/sys/bus/pci/devices/$dev/driver/unbind" ]]; then
        echo "$dev" > "/sys/bus/pci/devices/$dev/driver/unbind" || true
      fi
      echo "" > "/sys/bus/pci/devices/$dev/driver_override" || true
      echo "$dev" > /sys/bus/pci/drivers_probe || true
    }

    prepare_begin() {
      mkdir -p "$STATE_DIR"
      log "Prepare begin for $GUEST_NAME"
      log "Configured GPU video: $GPU_VIDEO"
      log "Configured GPU audio: $GPU_AUDIO"
      log "Configured USB controller: $USB_CONTROLLER"

      stop_display_manager
      sleep 2
      unbind_consoles
      unbind_efi_framebuffer

      if [[ "$RELOAD_NVIDIA" == "1" ]]; then
        unload_nvidia
      fi

      modprobe vfio || true
      modprobe vfio_iommu_type1 || true
      modprobe vfio_pci || true

      bind_device_to_vfio "$GPU_VIDEO"
      bind_device_to_vfio "$GPU_AUDIO"
      bind_device_to_vfio "$USB_CONTROLLER"
    }

    release_end() {
      log "Release end for $GUEST_NAME"

      modprobe -r vfio_pci vfio_iommu_type1 vfio || true
      echo 1 > /sys/bus/pci/rescan || true
      sleep 1

      reprobe_device "$GPU_VIDEO"
      reprobe_device "$GPU_AUDIO"
      reprobe_device "$USB_CONTROLLER"

      if [[ "$RELOAD_NVIDIA" == "1" ]]; then
        load_nvidia
        nvidia-smi > /dev/null 2>&1 || true
      fi

      rebind_efi_framebuffer
      rebind_consoles
      start_display_manager
      rm -f "$DM_STATE_FILE"
    }

    if ! guest_matches; then
      exit 0
    fi

    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$STATE_DIR"

    case "$HOOK_PHASE/$HOOK_SUBPHASE" in
      prepare/begin)
        prepare_begin
        ;;
      release/end)
        release_end
        ;;
    esac
  '';
in
{
  options.passthrough.singleGpu = {
    enable = lib.mkEnableOption "single-GPU passthrough host preparation";

    vmName = lib.mkOption {
      type = lib.types.str;
      default = "win10-pab";
      description = "Compatibility guest name used when vmNames is empty.";
    };

    vmNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Guest names that should trigger the single-GPU libvirt hook.";
    };

    cpuVendor = lib.mkOption {
      type = lib.types.enum [
        "amd"
        "intel"
      ];
      default = "amd";
      description = "CPU vendor used to choose KVM and IOMMU settings.";
    };

    gpu.videoPci = lib.mkOption {
      type = lib.types.str;
      default = "0000:09:00.0";
      description = "PCI address for the passthrough GPU video function.";
    };

    gpu.audioPci = lib.mkOption {
      type = lib.types.str;
      default = "0000:09:00.1";
      description = "PCI address for the passthrough GPU audio function.";
    };

    usbControllerPci = lib.mkOption {
      type = lib.types.str;
      default = "0000:0b:00.3";
      description = "PCI address for the USB controller reserved for the guest.";
    };

    sharedDir = lib.mkOption {
      type = lib.types.str;
      default = "/srv/vm-shares/win10-pab-projects";
      description = "Shared directory path reserved for the passthrough guest.";
    };

    logFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/libvirt-win10-pab-hook.log";
      description = "Deprecated compatibility option; hook logs are per guest.";
    };

    displayManagers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "greetd"
        "greetd.service"
        "cosmic-greeter"
        "gdm"
        "sddm"
        "lightdm"
        "lxdm"
        "ly"
      ];
      description = "Display manager units the hook may stop and restart during GPU handoff.";
    };

    extraKernelParams = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra kernel parameters appended to the VFIO host settings.";
    };

    nvidia.enableModuleReload = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the hook unloads and reloads NVIDIA modules during handoff.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.journald.extraConfig = ''
      Storage=persistent
    '';

    boot.kernelParams =
      [
        (if cfg.cpuVendor == "amd" then "amd_iommu=on" else "intel_iommu=on")
        "iommu=pt"
      ]
      ++ cfg.extraKernelParams;

    boot.kernelModules =
      [
        "vfio"
        "vfio_pci"
        "vfio_iommu_type1"
        "bridge"
        "br_netfilter"
      ]
      ++ lib.optional (cfg.cpuVendor == "amd") "kvm-amd"
      ++ lib.optional (cfg.cpuVendor == "intel") "kvm-intel";

    users.users.${userSettings.username}.extraGroups = lib.mkAfter [
      "libvirtd"
      "kvm"
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
      hooks.qemu.single-gpu-passthrough = hookScript;
    };

    programs.virt-manager.enable = true;

    systemd.services.virtnetworkd.path = with pkgs; [
      dnsmasq
      iptables
    ];

    systemd.services.virtqemud.path = with pkgs; [
      qemu_kvm
      swtpm
      dmidecode
    ];

    environment.systemPackages = with pkgs; [
      libvirt
      pciutils
      qemu_kvm
      swtpm
      virtiofsd
    ];

    systemd.tmpfiles.rules = [
      "d ${builtins.dirOf cfg.sharedDir} 0755 root root -"
      "d ${cfg.sharedDir} 0755 ${userSettings.username} users -"
    ];
  };
}

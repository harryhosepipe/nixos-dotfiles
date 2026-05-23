{ pkgs, ... }:

{
  nixpkgs.overlays = [
    (_final: prev: {
      waybar = prev.waybar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../../../patches/waybar-hyprland-lua-workspace-click.patch
        ];
      });
    })
  ];

  boot = {
    # Keep the greeter screen calm by hiding routine boot and device chatter.
    # Serious errors can still show up, but warnings like noisy USB messages stay
    # in the journal instead of being printed over the login screen.
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
      "udev.log_level=3"
    ];
  };

  # This recipe is one complete Wayland desktop choice.
  # Hosts can swap it later for a different GUI recipe.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # Start Hyprland through its helper script so the session gets the
        # environment setup Hyprland expects on NixOS.
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.hyprland}/bin/start-hyprland";
        user = "greeter";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    hypridle
    hyprpaper
    grim
    slurp
    swaynotificationcenter
    swappy
    waybar
    wl-clipboard
    wofi
  ];
}

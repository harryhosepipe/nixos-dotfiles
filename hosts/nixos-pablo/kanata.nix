{ config, lib, pkgs, userSettings, ... }:
let
  kanataVersion = "1.12.0-prerelease-2";
  kanataSrc = pkgs.fetchFromGitHub {
    owner = "jtroo";
    repo = "kanata";
    rev = "v${kanataVersion}";
    hash = "sha256-bNUlQBsyGxCu3GHP+qgrYLikLagXxzLjjuZFZFi7Vzk=";
  };
  kanataPrerelease = pkgs.kanata.overrideAttrs (_finalAttrs: _prevAttrs: {
    version = kanataVersion;
    src = kanataSrc;

    cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
      pname = "kanata";
      version = kanataVersion;
      src = kanataSrc;
      hash = "sha256-da7kmSvm+z6C+RPqEBEY9PNWxrAEQ8h/ZGDvS9WJ1J8=";
    };

    doCheck = false;
  });
in
{
  environment.systemPackages = [
    kanataPrerelease
  ];

  services.kanata = {
    enable = false;
    package = kanataPrerelease;

    keyboards.internal = {
      devices = [ ];
      configFile = "/home/${userSettings.username}/${userSettings.dotFiles}/config/kanata/kanata.kbd";
    };
  };

  systemd.services.kanata-internal.serviceConfig = lib.mkIf config.services.kanata.enable {
    DynamicUser = lib.mkForce false;
    ProtectHome = lib.mkForce false;
    User = userSettings.username;
  };
}

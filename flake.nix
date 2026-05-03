{
  description = "Learning-first NixOS setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    userSettings = {
      name = "Pablo";
      username = "pablo";
      dotFiles = "nix-dot";
      email = "pablo@renderbros.com";
    };
    system = {
      hostName = "nixos-pablo";
    };
    # This file stays small on purpose.
    # The host list lives in hosts.nix and each machine has its own folder.
    hosts = import ./hosts.nix {
      inherit userSettings system;
    };
    mkNixosConfiguration = host:
      nixpkgs.lib.nixosSystem {
        system = host.system;
        specialArgs = {
          inherit host;
          inherit userSettings;
          inherit system;
        };
        modules = [
          (host.path + "/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
                inherit userSettings;
              };
              users.${host.user} = import (host.path + "/home.nix");
              backupFileExtension = "backup";
            };
          }
        ];
      };
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs (_: mkNixosConfiguration) hosts;
  };
}

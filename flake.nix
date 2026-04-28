{
  description = "Learning-first NixOS setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixCats.url = "github:BirdeeHub/nixCats-nvim";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{
    nixpkgs,
    home-manager,
    ...
  }:
    let
      # This file stays small on purpose.
      # The host list lives in hosts.nix and each machine has its own folder.
      hosts = import ./hosts.nix;
      mainHost = hosts.desktop;
    in
    {
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = mainHost.system;
        specialArgs = {
          host = mainHost;
        };
        modules = [
          (mainHost.path + "/configuration.nix")
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {
                inherit inputs;
              };
              users.${mainHost.user} = import (mainHost.path + "/home.nix");
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}

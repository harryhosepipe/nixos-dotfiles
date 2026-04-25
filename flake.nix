{
  description = "Learning-first NixOS setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # This file stays small on purpose.
      # The host list lives in hosts.nix and each machine has its own folder.
      hosts = import ./hosts.nix;
      mainHost = hosts.nixos-btw;
    in
    {
      nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
        system = mainHost.system;
        modules = [
          ./hosts/nixos-btw/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${mainHost.user} = import ./hosts/nixos-btw/home.nix;
              backupFileExtension = "backup";
            };
          }
        ];
      };
    };
}

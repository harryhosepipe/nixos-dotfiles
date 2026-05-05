{
  description = "NixOS desktop, laptop and server config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-unstable,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";

    mkHost = hostname: let
      userSettings = import ./hosts/${hostname}/settings.nix;
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
      nixpkgs.lib.nixosSystem {
        inherit system;

        specialArgs = {
          inherit inputs self userSettings pkgs-unstable;
        };

        modules = [
          ./hosts/${hostname}

          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = {
                inherit inputs self userSettings pkgs-unstable;
              };

              users.${userSettings.username} = import ./users/${userSettings.username}/home.nix;
            };
          }
        ];
      };
  in {
    nixosConfigurations = {
      desktop = mkHost "desktop";
      laptop = mkHost "laptop";
      server = mkHost "server";
    };
  };
}

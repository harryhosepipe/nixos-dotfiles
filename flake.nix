{
  description = "Learning-first NixOS setup";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix/v0.143.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-desktop-linux = {
      url = "path:./nix/codex-desktop-linux-patched";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.upstream.inputs.nixpkgs.follows = "nixpkgs";
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    handy = {
      url = "github:cjpais/Handy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr/v0.6.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
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
    mainHost = hosts.desktop;
  in {
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = mainHost.system;
      specialArgs = {
        host = mainHost;
        inherit userSettings;
        inherit system;
      };
      modules = [
        (mainHost.path + "/configuration.nix")
        inputs.handy.nixosModules.default
        {
          programs.handy.enable = true;
        }
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs;
              inherit userSettings;
            };
            users.${mainHost.user} = import (mainHost.path + "/home.nix");
            backupFileExtension = "backup";
          };
        }
      ];
    };
  };
}

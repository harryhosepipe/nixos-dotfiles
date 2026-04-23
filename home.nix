{ config, pkgs, ... }:

{
  home.username = "pablo";
  home.homeDirectory = "/home/pablo";
  home.stateVersion = "25.05";
  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use nixos, btw";
      nrs = "sudo nixos-rebuild switch --flake 'path:/home/pablo/dotfiles#nixos-btw'";
    };
  };
  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/ansible_razer";
        identitiesOnly = true;
        addKeysToAgent = "yes";
      };
    };
  };

 imports = [
	./git.nix
	./codex.nix
 ];
 home.file.".config/qtile".source = ./config/qtile;
 home.file.".config/nvim".source = ./config/nvim;

 home.packages = with pkgs; [
	neovim
	ripgrep
	nil
	nixpkgs-fmt
	nodejs
	gcc
	doppler
	];	
}

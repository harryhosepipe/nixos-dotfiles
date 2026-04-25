{ config, pkgs, ... }:

let
  dotfiles = "${config.home.homeDirectory}/dotfiles/config";
  shellSettings = import ./shells/settings.nix;
  fzfShare = "${pkgs.fzf}/share/fzf";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  configDirs = {
    bash = "bash";
    qtile = "qtile";
    nvim = "nvim";
    zsh = "zsh";
    fish = "fish";
    "oh-my-posh" = "oh-my-posh";
  };

  configFiles = {
    "codex/config.toml" = "codex/config.toml";
  };
in

{
  home.username = "pablo";
  home.homeDirectory = "/home/pablo";
  home.stateVersion = "25.05";
  home.sessionPath = shellSettings.sessionPath;
  home.sessionVariables = {
    CODEX_HOME = "${config.xdg.configHome}/codex";
    FZF_SHARE = fzfShare;
    _ZO_ECHO = "1";
    _ZO_EXCLUDE_DIRS = "${config.home.homeDirectory}/.cache:${config.home.homeDirectory}/.local/share/Trash:${config.home.homeDirectory}/dotfiles/config/codex";
  };
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
      };
      "github.com" = {
        user = "git";
        hostname = "github.com";
        identityFile = "~/.ssh/ansible_razer";
        identitiesOnly = true;
      };
    };
  };
  services.ssh-agent.enable = true;

 imports = [
	./git.nix
	./codex.nix
 ];
 home.file.".bashrc".source = createSymlink "${dotfiles}/bash/.bashrc";
 home.file.".bash_profile".source = createSymlink "${dotfiles}/bash/.bash_profile";
 home.file.".profile".source = createSymlink "${dotfiles}/profile/.profile";
 home.file.".zshenv".source = createSymlink "${dotfiles}/zsh/.zshenv";
 xdg.configFile =
   (builtins.mapAttrs (name: subpath: {
     source = createSymlink "${dotfiles}/${subpath}";
     recursive = true;
   }) configDirs)
   // (builtins.mapAttrs (name: subpath: {
     source = createSymlink "${dotfiles}/${subpath}";
   }) configFiles);

 home.packages = with pkgs; [
	neovim
	ripgrep
	nil
	nixpkgs-fmt
	nodejs
	gcc
	doppler
  bat
  btop
  oh-my-posh
  fzf
  zoxide
	];	
}

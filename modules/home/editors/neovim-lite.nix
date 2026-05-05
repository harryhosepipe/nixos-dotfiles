{
  config,
  pkgs,
  pkgs-unstable,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
in {
  programs.neovim = {
    enable = true;
    package = pkgs-unstable.neovim;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
    extraPackages = with pkgs; [
      ripgrep
      fd
    ];
    extraLuaConfig = ''
      dofile(vim.fn.expand("~/.config/nvim/lua/config/options.lua"))
    '';
  };

  xdg.configFile."nvim".source = createSymlink "${dotfiles}/nvim";
}

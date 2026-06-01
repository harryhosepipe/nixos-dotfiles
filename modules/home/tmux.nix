{ pkgs, ... }:
let
  vimTmuxNavigator = pkgs.writeShellScriptBin "tmux-vim-tmux-navigator" ''
    exec ${pkgs.tmuxPlugins.vim-tmux-navigator}/share/tmux-plugins/vim-tmux-navigator/vim-tmux-navigator.tmux "$@"
  '';
in
{
  home.packages = with pkgs; [
    tmux
    vimTmuxNavigator
  ];
}

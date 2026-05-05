{
  config,
  pkgs,
  ...
}: let
  shellSettings = import ../../../shells/settings.nix;
  fzfShare = "${pkgs.fzf}/share/fzf";
in {
  imports = [
    ./common.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initExtra = ''
      if [ -f "${config.xdg.configHome}/zsh/.zshrc" ]; then
        source "${config.xdg.configHome}/zsh/.zshrc"
      fi

      ${
        if shellSettings.enableFzf
        then ''
          if [ -f "${fzfShare}/key-bindings.zsh" ]; then
            source "${fzfShare}/key-bindings.zsh"
          fi

          if [ -f "${fzfShare}/completion.zsh" ]; then
            source "${fzfShare}/completion.zsh"
          fi
        ''
        else ""
      }
    '';
  };
}

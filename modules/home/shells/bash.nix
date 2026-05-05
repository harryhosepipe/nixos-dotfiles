{config, ...}: {
  imports = [
    ./common.nix
  ];

  programs.bash = {
    enable = true;
    bashrcExtra = ''
      if [ -f "${config.xdg.configHome}/bash/.bashrc" ]; then
        source "${config.xdg.configHome}/bash/.bashrc"
      fi
    '';
  };
}

{config, ...}: {
  imports = [
    ./common.nix
  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      if test -f "${config.xdg.configHome}/fish/config.fish"
        source "${config.xdg.configHome}/fish/config.fish"
      end
    '';
  };
}

{
  lib,
  pkgs,
  userSettings,
  ...
}: let
  shellPackages = {
    bash = pkgs.bashInteractive;
    zsh = pkgs.zsh;
    fish = pkgs.fish;
  };
in {
  users.users.${userSettings.username} = {
    isNormalUser = true;
    description = userSettings.fullName;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = shellPackages.${userSettings.shell};
    packages = with pkgs; [
      tree
    ];
  };

  security.sudo.extraRules = lib.mkIf userSettings.passwordlessSudo [
    {
      users = [userSettings.username];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  programs.zsh.enable = true;
  programs.fish.enable = true;
}

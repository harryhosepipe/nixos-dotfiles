{
  config,
  userSettings,
  ...
}: let
  dotfiles = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;
in {
  xdg.configFile."qtile".source = createSymlink "${dotfiles}/qtile";
}

{ config
, lib
, userSettings
, ...
}:
let
  cfg = config.dotfiles;
  dotfilesRoot = "${config.home.homeDirectory}/${userSettings.dotFiles}/config";
  createSymlink = path: config.lib.file.mkOutOfStoreSymlink path;

  publishConfigDir = _name: subpath: {
    source = createSymlink "${dotfilesRoot}/${subpath}";
    recursive = true;
  };

  publishConfigEntry = _name: subpath: {
    source = createSymlink "${dotfilesRoot}/${subpath}";
  };

  publishHomeFile = _name: subpath: {
    source = createSymlink "${dotfilesRoot}/${subpath}";
  };
in
{
  options.dotfiles = {
    configDirs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Config directories published from the dotfiles repo into XDG config.";
    };

    configEntries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Config files or symlinked directories published from the dotfiles repo into XDG config.";
    };

    homeFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Home-directory files published from the dotfiles repo.";
    };
  };

  config = {
    xdg.configFile =
      (lib.mapAttrs publishConfigDir cfg.configDirs)
      // (lib.mapAttrs publishConfigEntry cfg.configEntries);

    home.file = lib.mapAttrs publishHomeFile cfg.homeFiles;
  };
}

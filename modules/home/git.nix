{ userSettings, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = userSettings.name;
      user.email = userSettings.email;
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };
}

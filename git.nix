{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "pablo";
      user.email = "pablo@renderbros.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };
}

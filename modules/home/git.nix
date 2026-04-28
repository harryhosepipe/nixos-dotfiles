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
      # Always talk to GitHub over SSH so git uses the local SSH key setup.
      url."git@github.com:".insteadOf = "https://github.com/";
      # Keep the key choice explicit so GitHub pushes do not depend on whatever
      # default SSH identity happens to be loaded first.
      core.sshCommand = "ssh -i ~/.ssh/ansible_razer -o IdentitiesOnly=yes";
    };
  };
}

{ ... }:

{
  # This recipe is one complete desktop choice.
  # Hosts can swap it later for a different GUI recipe.
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile.enable = true;
  };

  services.displayManager.ly.enable = true;
}

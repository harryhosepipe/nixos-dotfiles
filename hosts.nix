{
  userSettings,
  system,
}: {
  # This file is the short host list for the repo.
  # Each machine says which user it belongs to, what its real hostname is,
  # and where its own host files live.
  desktop = {
    system = "x86_64-linux";
    user = userSettings.username;
    hostName = system.hostName;
    path = ./hosts/nixos-pablo;
  };
}

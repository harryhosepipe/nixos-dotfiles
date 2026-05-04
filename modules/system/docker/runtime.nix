{userSettings, ...}: {
  # Reusable Docker runtime.
  # App workloads should import this instead of enabling Docker themselves.
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  users.users.${userSettings.username}.extraGroups = ["docker"];
}

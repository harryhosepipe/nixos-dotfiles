{
  lib,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/manifest";
  envFile = "${dataDir}/manifest.env";
  networkName = "manifest";
in {
  imports = [
    ../docker/runtime.nix
  ];

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 root root -"
    "d ${dataDir}/postgres 0700 root root -"
  ];

  system.activationScripts.manifestSecretsCheck.text = ''
    if [ ! -f ${lib.escapeShellArg envFile} ]; then
      echo "Missing ${envFile}"
      echo "Create it with:"
      echo "  sudo install -d -m 0700 ${dataDir}"
      echo "  sudoedit ${envFile}"
      echo
      echo "Required keys:"
      echo "  BETTER_AUTH_SECRET=<openssl rand -hex 32>"
      echo "  MANIFEST_ENCRYPTION_KEY=<openssl rand -hex 32>"
      echo "  POSTGRES_PASSWORD=<strong database password>"
      echo "  DATABASE_URL=postgresql://manifest:<same password>@manifest-postgres:5432/manifest"
      exit 1
    fi

    for key in BETTER_AUTH_SECRET MANIFEST_ENCRYPTION_KEY POSTGRES_PASSWORD DATABASE_URL; do
      if ! grep -qE "^$key=.+" ${lib.escapeShellArg envFile}; then
        echo "Missing required key '$key' in ${envFile}"
        exit 1
      fi
    done
  '';

  systemd.services.docker-network-manifest = {
    description = "Create Docker network for Manifest";
    wantedBy = ["multi-user.target"];
    requires = ["docker.service"];
    after = ["docker.service"];
    before = [
      "docker-manifest-postgres.service"
      "docker-manifest.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [pkgs.docker];
    script = ''
      docker network inspect ${networkName} >/dev/null 2>&1 || docker network create ${networkName}
    '';
  };

  virtualisation.oci-containers.containers = {
    manifest-postgres = {
      image = "postgres:16-alpine@sha256:20edbde7749f822887a1a022ad526fde0a47d6b2be9a8364433605cf65099416";
      autoStart = false;
      pull = "missing";
      environment = {
        POSTGRES_USER = "manifest";
        POSTGRES_DB = "manifest";
      };
      environmentFiles = [envFile];
      volumes = [
        "${dataDir}/postgres:/var/lib/postgresql/data"
      ];
      networks = [networkName];
      extraOptions = [
        "--health-cmd=pg_isready -U manifest"
        "--health-interval=5s"
        "--health-timeout=3s"
        "--health-retries=5"
        "--security-opt=no-new-privileges:true"
      ];
    };

    manifest = {
      image = "manifestdotbuild/manifest:latest";
      autoStart = false;
      pull = "always";
      dependsOn = ["manifest-postgres"];
      environment = {
        PORT = "2099";
        BETTER_AUTH_URL = "http://localhost:2099";
        OLLAMA_HOST = "http://host.docker.internal:11434";
        SEED_DATA = "false";
        NODE_ENV = "production";
        SELF_HOSTED = "true";
      };
      environmentFiles = [envFile];
      ports = [
        "127.0.0.1:2099:2099"
      ];
      networks = [networkName];
      extraOptions = [
        "--add-host=host.docker.internal:host-gateway"
        "--security-opt=no-new-privileges:true"
      ];
    };
  };

  systemd.services.docker-manifest = {
    after = [
      "docker-network-manifest.service"
      "docker-manifest-postgres.service"
    ];
    requires = [
      "docker-network-manifest.service"
      "docker-manifest-postgres.service"
    ];
    serviceConfig = {
      Restart = lib.mkForce "always";
      RestartSec = "10s";
    };
  };

  systemd.services.docker-manifest-postgres = {
    after = ["docker-network-manifest.service"];
    requires = ["docker-network-manifest.service"];
  };
}

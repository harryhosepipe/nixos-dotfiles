{
  lib,
  pkgs,
  ...
}: let
  dataDir = "/var/lib/penpot";
  networkName = "penpot";
  penpotVersion = "2.15";
  publicUri = "http://localhost:9001";
  secretKey = "penpot-local-secret-key";
  databasePassword = "penpot";
  commonFlags = "disable-email-verification enable-smtp enable-prepl-server disable-secure-session-cookies enable-mcp";
  bodySize = "367001600";
in {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0700 root root -"
    "d ${dataDir}/assets 0750 1001 1001 -"
    "d ${dataDir}/postgres 0700 999 999 -"
  ];

  systemd.services.docker-network-penpot = {
    description = "Create Docker network for Penpot";
    wantedBy = ["multi-user.target"];
    requires = ["docker.service"];
    after = ["docker.service"];
    before = [
      "docker-penpot-postgres.service"
      "docker-penpot-valkey.service"
      "docker-penpot-mailcatch.service"
      "docker-penpot-mcp.service"
      "docker-penpot-exporter.service"
      "docker-penpot-backend.service"
      "docker-penpot-frontend.service"
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
    penpot-postgres = {
      image = "postgres:15";
      autoStart = false;
      pull = "missing";
      environment = {
        POSTGRES_INITDB_ARGS = "--data-checksums";
        POSTGRES_DB = "penpot";
        POSTGRES_USER = "penpot";
        POSTGRES_PASSWORD = databasePassword;
      };
      volumes = [
        "${dataDir}/postgres:/var/lib/postgresql/data"
      ];
      networks = [networkName];
      extraOptions = [
        "--health-cmd=pg_isready -U penpot"
        "--health-interval=2s"
        "--health-timeout=10s"
        "--health-retries=5"
        "--health-start-period=2s"
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-valkey = {
      image = "valkey/valkey:8.1";
      autoStart = false;
      pull = "missing";
      environment = {
        VALKEY_EXTRA_FLAGS = "--maxmemory 128mb --maxmemory-policy volatile-lfu";
      };
      networks = [networkName];
      extraOptions = [
        "--health-cmd=valkey-cli ping | grep PONG"
        "--health-interval=1s"
        "--health-timeout=3s"
        "--health-retries=5"
        "--health-start-period=3s"
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-mailcatch = {
      image = "sj26/mailcatcher:latest";
      autoStart = false;
      pull = "always";
      ports = [
        "127.0.0.1:1080:1080"
      ];
      networks = [networkName];
      extraOptions = [
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-mcp = {
      image = "penpotapp/mcp:${penpotVersion}";
      autoStart = false;
      pull = "missing";
      networks = [networkName];
      extraOptions = [
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-exporter = {
      image = "penpotapp/exporter:${penpotVersion}";
      autoStart = false;
      pull = "missing";
      dependsOn = ["penpot-valkey"];
      environment = {
        PENPOT_SECRET_KEY = secretKey;
        PENPOT_PUBLIC_URI = "http://penpot-frontend:8080";
        PENPOT_REDIS_URI = "redis://penpot-valkey/0";
      };
      networks = [networkName];
      extraOptions = [
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-backend = {
      image = "penpotapp/backend:${penpotVersion}";
      autoStart = false;
      pull = "missing";
      dependsOn = [
        "penpot-postgres"
        "penpot-valkey"
      ];
      environment = {
        PENPOT_FLAGS = commonFlags;
        PENPOT_PUBLIC_URI = publicUri;
        PENPOT_HTTP_SERVER_MAX_BODY_SIZE = bodySize;
        PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE = bodySize;
        PENPOT_SECRET_KEY = secretKey;
        PENPOT_DATABASE_URI = "postgresql://penpot-postgres/penpot";
        PENPOT_DATABASE_USERNAME = "penpot";
        PENPOT_DATABASE_PASSWORD = databasePassword;
        PENPOT_REDIS_URI = "redis://penpot-valkey/0";
        PENPOT_OBJECTS_STORAGE_BACKEND = "fs";
        PENPOT_OBJECTS_STORAGE_FS_DIRECTORY = "/opt/data/assets";
        PENPOT_TELEMETRY_ENABLED = "true";
        PENPOT_TELEMETRY_REFERER = "nixos-oci-containers";
        PENPOT_SMTP_DEFAULT_FROM = "no-reply@example.com";
        PENPOT_SMTP_DEFAULT_REPLY_TO = "no-reply@example.com";
        PENPOT_SMTP_HOST = "penpot-mailcatch";
        PENPOT_SMTP_PORT = "1025";
        PENPOT_SMTP_TLS = "false";
        PENPOT_SMTP_SSL = "false";
      };
      volumes = [
        "${dataDir}/assets:/opt/data/assets"
      ];
      networks = [networkName];
      extraOptions = [
        "--security-opt=no-new-privileges:true"
      ];
    };

    penpot-frontend = {
      image = "penpotapp/frontend:${penpotVersion}";
      autoStart = false;
      pull = "missing";
      dependsOn = [
        "penpot-backend"
        "penpot-exporter"
        "penpot-mcp"
      ];
      environment = {
        PENPOT_FLAGS = commonFlags;
        PENPOT_PUBLIC_URI = publicUri;
        PENPOT_HTTP_SERVER_MAX_BODY_SIZE = bodySize;
        PENPOT_HTTP_SERVER_MAX_MULTIPART_BODY_SIZE = bodySize;
      };
      ports = [
        "127.0.0.1:9001:8080"
      ];
      volumes = [
        "${dataDir}/assets:/opt/data/assets"
      ];
      networks = [networkName];
      extraOptions = [
        "--security-opt=no-new-privileges:true"
      ];
    };
  };

  systemd.services = {
    docker-penpot-postgres = {
      after = ["docker-network-penpot.service"];
      requires = ["docker-network-penpot.service"];
    };

    docker-penpot-valkey = {
      after = ["docker-network-penpot.service"];
      requires = ["docker-network-penpot.service"];
    };

    docker-penpot-mailcatch = {
      after = ["docker-network-penpot.service"];
      requires = ["docker-network-penpot.service"];
    };

    docker-penpot-mcp = {
      after = ["docker-network-penpot.service"];
      requires = ["docker-network-penpot.service"];
    };

    docker-penpot-exporter = {
      after = [
        "docker-network-penpot.service"
        "docker-penpot-valkey.service"
      ];
      requires = [
        "docker-network-penpot.service"
        "docker-penpot-valkey.service"
      ];
      serviceConfig = {
        Restart = lib.mkForce "always";
        RestartSec = "10s";
      };
    };

    docker-penpot-backend = {
      after = [
        "docker-network-penpot.service"
        "docker-penpot-postgres.service"
        "docker-penpot-valkey.service"
      ];
      requires = [
        "docker-network-penpot.service"
        "docker-penpot-postgres.service"
        "docker-penpot-valkey.service"
      ];
      serviceConfig = {
        Restart = lib.mkForce "always";
        RestartSec = "10s";
      };
    };

    docker-penpot-frontend = {
      after = [
        "docker-network-penpot.service"
        "docker-penpot-backend.service"
        "docker-penpot-exporter.service"
        "docker-penpot-mcp.service"
      ];
      requires = [
        "docker-network-penpot.service"
        "docker-penpot-backend.service"
        "docker-penpot-exporter.service"
        "docker-penpot-mcp.service"
      ];
      serviceConfig = {
        Restart = lib.mkForce "always";
        RestartSec = "10s";
      };
    };
  };
}

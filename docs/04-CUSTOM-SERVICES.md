# Custom Services (Outside Self Host Blocks)

For services not provided by SHB, you can use standard NixOS modules with SHB's nginx block for reverse proxy and SSL.

## Miniflux RSS Reader

Create `modules/services/miniflux.nix`:

```nix
{ config, lib, pkgs, domain, ... }:
let
  subdomain = "rss";
  fqdn = "${subdomain}.${domain}";
  port = 8085;
in
{
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/admin_credentials".path;
    config = {
      LISTEN_ADDR = "127.0.0.1:${toString port}";
      BASE_URL = "https://${fqdn}/";
      RUN_MIGRATIONS = "1";
      
      # Optional: OAuth2/OIDC integration with Authelia
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets."miniflux/oauth_secret".path;
      OAUTH2_REDIRECT_URL = "https://${fqdn}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${domain}/.well-known/openid-configuration";
      OAUTH2_USER_CREATION = "1";
    };
  };

  # Nginx reverse proxy using SHB's nginx block
  shb.nginx.vhosts.${fqdn} = {
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
    };
  };

  # Register with Authelia if using SSO
  shb.authelia.oidcClients = [
    {
      client_id = "miniflux";
      client_name = "Miniflux RSS";
      client_secret.source = config.sops.secrets."miniflux/oauth_secret_authelia".path;
      public = false;
      authorization_policy = "one_factor";
      scopes = [ "openid" "email" "profile" ];
      redirect_uris = [ "https://${fqdn}/oauth2/oidc/callback" ];
    }
  ];

  # Secrets
  sops.secrets."miniflux/admin_credentials" = {
    sopsFile = ../homelab/secrets.yaml;
  };
  sops.secrets."miniflux/oauth_secret" = {
    sopsFile = ../homelab/secrets.yaml;
    owner = "miniflux";
  };
  sops.secrets."miniflux/oauth_secret_authelia" = {
    sopsFile = ../homelab/secrets.yaml;
    key = "miniflux/oauth_secret";
    owner = "authelia";
  };
}
```

Add to `homelab/secrets.yaml`:

```yaml
miniflux/admin_credentials: |
  ADMIN_USERNAME=admin
  ADMIN_PASSWORD=your-secure-password
miniflux/oauth_secret: "<random 64 hex chars>"
```

## Generic Pattern for Other Services

For any NixOS service not in SHB:

```nix
{ config, lib, pkgs, domain, ... }:
let
  serviceName = "myservice";
  subdomain = "myservice";
  fqdn = "${subdomain}.${domain}";
  port = 8080;  # Internal port
in
{
  # 1. Enable the service
  services.${serviceName} = {
    enable = true;
    # Service-specific config...
  };

  # 2. Add subdomain to SSL cert
  shb.certs.certs.letsencrypt.${domain}.extraDomains = [ fqdn ];

  # 3. Configure reverse proxy
  shb.nginx.vhosts.${fqdn} = {
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
      # Optional: WebSocket support
      # extraConfig = ''
      #   proxy_http_version 1.1;
      #   proxy_set_header Upgrade $http_upgrade;
      #   proxy_set_header Connection "upgrade";
      # '';
    };
  };

  # 4. (Optional) Add SSO via Authelia forward auth
  # shb.nginx.vhosts.${fqdn}.authelia = {
  #   enable = true;
  #   endpoint = "https://auth.${domain}";
  # };
}
```

## Services to Consider

Other self-hostable services you might want:

| Service | NixOS Module | Purpose |
|---------|--------------|---------|
| Immich | `services.immich` | Photo management |
| Paperless-ngx | `services.paperless` | Document management |
| Syncthing | `services.syncthing` | File sync |
| Radarr/Sonarr | `services.radarr` | Media automation |
| Transmission | `services.transmission` | Torrents |
| Pi-hole/AdGuard | `services.adguardhome` | DNS/Adblock |
| Uptime Kuma | Container | Status monitoring |

## Using Docker/Podman for Unsupported Services

For services without NixOS modules:

```nix
{ config, lib, pkgs, domain, ... }:
{
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      myapp = {
        image = "myapp:latest";
        ports = [ "127.0.0.1:8080:8080" ];
        volumes = [
          "/var/lib/myapp:/data"
        ];
        environment = {
          TZ = "America/New_York";
        };
      };
    };
  };

  # Then add nginx reverse proxy as above
  shb.nginx.vhosts."myapp.${domain}" = {
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
    };
  };
}
```

{ config, lib, pkgs, ... }:
let
  domain = "knightoffaith.systems";
  subdomain = "rss";
  fqdn = "${subdomain}.${domain}";
  port = 8085;
in
{
  # Miniflux RSS Reader (not part of SHB, using native NixOS module)
  services.miniflux = {
    enable = true;
    adminCredentialsFile = config.sops.secrets."miniflux/admin_credentials".path;
    config = {
      LISTEN_ADDR = "127.0.0.1:${toString port}";
      BASE_URL = "https://${fqdn}/";
      RUN_MIGRATIONS = "1";
      
      # Optional: Enable metrics for Prometheus
      METRICS_COLLECTOR = "1";
      METRICS_ALLOWED_NETWORKS = "127.0.0.1/8";
      
      # OAuth2/OIDC integration with Authelia
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      OAUTH2_CLIENT_SECRET_FILE = config.sops.secrets."miniflux/oauth_secret".path;
      OAUTH2_REDIRECT_URL = "https://${fqdn}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${domain}/.well-known/openid-configuration";
      OAUTH2_USER_CREATION = "1";
    };
  };

  # Nginx reverse proxy
  shb.nginx.vhosts.${fqdn} = {
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString port}";
    };
  };

  # Register Miniflux as OIDC client with Authelia
  shb.authelia.oidcClients = [
    {
      client_id = "miniflux";
      client_name = "Miniflux RSS Reader";
      client_secret.source = config.sops.secrets."miniflux/oauth_secret_authelia".path;
      public = false;
      authorization_policy = "one_factor";
      scopes = [ "openid" "email" "profile" ];
      redirect_uris = [ "https://${fqdn}/oauth2/oidc/callback" ];
    }
  ];

  # SOPS secrets
  sops.secrets."miniflux/admin_credentials" = {
    sopsFile = ../../homelab/secrets.yaml;
    mode = "0400";
  };
  
  sops.secrets."miniflux/oauth_secret" = {
    sopsFile = ../../homelab/secrets.yaml;
    owner = "miniflux";
    mode = "0400";
  };
  
  sops.secrets."miniflux/oauth_secret_authelia" = {
    sopsFile = ../../homelab/secrets.yaml;
    key = "miniflux/oauth_secret";
    owner = "authelia-auth.${domain}";
    mode = "0400";
  };
}

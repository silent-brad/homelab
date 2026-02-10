{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.vaultwarden = {
    enable = true;
    subdomain = "vault";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    # SSO via Authelia
    sso = {
      enable = true;
      endpoint = "https://auth.${domain}";
      secret.result = config.shb.sops.secrets."vaultwarden/sso/secret".result;
      secretForAuthelia.result = config.shb.sops.secrets."vaultwarden/sso/secretForAuthelia".result;
    };
  };

  # SOPS secrets
  shb.sops.secrets."vaultwarden/sso/secret".request = config.shb.vaultwarden.sso.secret.request;
  
  shb.sops.secrets."vaultwarden/sso/secretForAuthelia" = {
    request = config.shb.vaultwarden.sso.secretForAuthelia.request;
    settings.key = "vaultwarden/sso/secret";
  };
}

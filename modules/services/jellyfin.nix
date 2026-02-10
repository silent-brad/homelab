{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.jellyfin = {
    enable = true;
    subdomain = "media";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    # LDAP integration
    ldap = {
      enable = true;
      host = "127.0.0.1";
      port = config.shb.lldap.ldapPort;
      dcdomain = config.shb.lldap.dcdomain;
      adminPassword.result = config.shb.sops.secrets."jellyfin/ldap/admin_password".result;
    };
    
    # SSO via Authelia (forward auth)
    sso = {
      enable = true;
      endpoint = "https://auth.${domain}";
      secret.result = config.shb.sops.secrets."jellyfin/sso/secret".result;
      secretForAuthelia.result = config.shb.sops.secrets."jellyfin/sso/secretForAuthelia".result;
    };
  };

  # SOPS secrets
  shb.sops.secrets."jellyfin/ldap/admin_password" = {
    request = config.shb.jellyfin.ldap.adminPassword.request;
    settings.key = "lldap/user_password";
  };
  
  shb.sops.secrets."jellyfin/sso/secret".request = config.shb.jellyfin.sso.secret.request;
  
  shb.sops.secrets."jellyfin/sso/secretForAuthelia" = {
    request = config.shb.jellyfin.sso.secretForAuthelia.request;
    settings.key = "jellyfin/sso/secret";
  };
}

{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.nextcloud = {
    enable = true;
    subdomain = "cloud";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    adminPassword.result = config.shb.sops.secrets."nextcloud/admin_password".result;
    
    # LDAP integration for user management
    apps.ldap = {
      enable = true;
      host = "127.0.0.1";
      port = config.shb.lldap.ldapPort;
      dcdomain = config.shb.lldap.dcdomain;
      adminPassword.result = config.shb.sops.secrets."nextcloud/ldap/admin_password".result;
    };
    
    # SSO via Authelia
    apps.sso = {
      enable = true;
      endpoint = "https://auth.${domain}";
      secret.result = config.shb.sops.secrets."nextcloud/sso/secret".result;
      secretForAuthelia.result = config.shb.sops.secrets."nextcloud/sso/secretForAuthelia".result;
    };
  };

  # SOPS secrets
  shb.sops.secrets."nextcloud/admin_password".request = config.shb.nextcloud.adminPassword.request;
  
  shb.sops.secrets."nextcloud/ldap/admin_password" = {
    request = config.shb.nextcloud.apps.ldap.adminPassword.request;
    settings.key = "lldap/user_password";
  };
  
  shb.sops.secrets."nextcloud/sso/secret".request = config.shb.nextcloud.apps.sso.secret.request;
  
  shb.sops.secrets."nextcloud/sso/secretForAuthelia" = {
    request = config.shb.nextcloud.apps.sso.secretForAuthelia.request;
    settings.key = "nextcloud/sso/secret";
  };
}

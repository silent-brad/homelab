{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.forgejo = {
    enable = true;
    subdomain = "git";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    # LDAP integration
    ldap = {
      enable = true;
      host = "127.0.0.1";
      port = config.shb.lldap.ldapPort;
      dcdomain = config.shb.lldap.dcdomain;
      adminPassword.result = config.shb.sops.secrets."forgejo/ldap/admin_password".result;
    };
    
    # SSO via Authelia
    sso = {
      enable = true;
      endpoint = "https://auth.${domain}";
      secret.result = config.shb.sops.secrets."forgejo/sso/secret".result;
      secretForAuthelia.result = config.shb.sops.secrets."forgejo/sso/secretForAuthelia".result;
    };
  };

  # SOPS secrets
  shb.sops.secrets."forgejo/ldap/admin_password" = {
    request = config.shb.forgejo.ldap.adminPassword.request;
    settings.key = "lldap/user_password";
  };
  
  shb.sops.secrets."forgejo/sso/secret".request = config.shb.forgejo.sso.secret.request;
  
  shb.sops.secrets."forgejo/sso/secretForAuthelia" = {
    request = config.shb.forgejo.sso.secretForAuthelia.request;
    settings.key = "forgejo/sso/secret";
  };
}

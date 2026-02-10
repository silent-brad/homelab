{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.authelia = {
    enable = true;
    subdomain = "auth";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};

    # LDAP backend
    ldapHostname = "127.0.0.1";
    ldapPort = config.shb.lldap.ldapPort;
    dcdomain = config.shb.lldap.dcdomain;

    # SMTP configuration for password resets
    # UPDATE: Configure your SMTP provider
    smtp = {
      host = "smtp.mailgun.org";
      port = 587;
      username = "postmaster@mg.${domain}";
      from_address = "auth@${domain}";
      password.result = config.shb.sops.secrets."authelia/smtp_password".result;
    };

    # All required secrets
    secrets = {
      jwtSecret.result = config.shb.sops.secrets."authelia/jwt_secret".result;
      ldapAdminPassword.result = config.shb.sops.secrets."authelia/ldap_admin_password".result;
      sessionSecret.result = config.shb.sops.secrets."authelia/session_secret".result;
      storageEncryptionKey.result = config.shb.sops.secrets."authelia/storage_encryption_key".result;
      identityProvidersOIDCHMACSecret.result = config.shb.sops.secrets."authelia/hmac_secret".result;
      identityProvidersOIDCIssuerPrivateKey.result = config.shb.sops.secrets."authelia/private_key".result;
    };
  };

  # SOPS secrets configuration
  shb.sops.secrets."authelia/jwt_secret".request = config.shb.authelia.secrets.jwtSecret.request;
  
  # Reuse LLDAP admin password for Authelia's LDAP connection
  shb.sops.secrets."authelia/ldap_admin_password" = {
    request = config.shb.authelia.secrets.ldapAdminPassword.request;
    settings.key = "lldap/user_password";
  };
  
  shb.sops.secrets."authelia/session_secret".request = config.shb.authelia.secrets.sessionSecret.request;
  shb.sops.secrets."authelia/storage_encryption_key".request = config.shb.authelia.secrets.storageEncryptionKey.request;
  shb.sops.secrets."authelia/hmac_secret".request = config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
  shb.sops.secrets."authelia/private_key".request = config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;
  shb.sops.secrets."authelia/smtp_password".request = config.shb.authelia.smtp.password.request;
}

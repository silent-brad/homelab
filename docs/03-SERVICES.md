# Self Host Blocks Services

## Overview

SHB provides unified configuration for services with:
- Automatic SSL certificates
- LDAP user management
- Single Sign-On (SSO)
- Monitoring dashboards
- Backups

## 1. Generate Secrets

All secrets are stored in `homelab/secrets.yaml` encrypted with SOPS.

```bash
# Generate random secrets for services
nix run nixpkgs#openssl -- rand -hex 64  # Use for each secret
```

Edit `homelab/secrets.yaml` (SOPS will encrypt automatically):

```bash
# Edit secrets (creates if doesn't exist)
sops homelab/secrets.yaml
```

Add these secrets:

```yaml
# User password
homelab/user/hashedPassword: "<run: mkpasswd -m sha-512>"

# LLDAP (LDAP server)
lldap/jwt_secret: "<random 64 hex chars>"
lldap/user_password: "<random password>"

# Authelia (SSO)
authelia/jwt_secret: "<random 64 hex chars>"
authelia/session_secret: "<random 64 hex chars>"
authelia/storage_encryption_key: "<random 64 hex chars>"
authelia/hmac_secret: "<random 64 hex chars>"
authelia/private_key: |
  <generate RSA key: openssl genrsa 4096>
authelia/smtp_password: "<your SMTP password>"

# Namecheap API
namecheap/credentials: |
  NAMECHEAP_API_USER=your_username
  NAMECHEAP_API_KEY=your_api_key

# Per-service SSO secrets (generate for each service you enable)
nextcloud/sso/secret: "<random 64 hex chars>"
vaultwarden/sso/secret: "<random 64 hex chars>"
forgejo/sso/secret: "<random 64 hex chars>"
jellyfin/sso/secret: "<random 64 hex chars>"
miniflux/admin_credentials: |
  ADMIN_USERNAME=admin
  ADMIN_PASSWORD=<your password>
```

## 2. Create Services Module

Create `modules/services.nix`:

```nix
{ config, lib, pkgs, ... }:
let
  domain = "knightoffaith.systems";
in
{
  imports = [
    ./blocks/ssl.nix
    ./blocks/ldap.nix
    ./blocks/authelia.nix
    ./services/nextcloud.nix
    ./services/vaultwarden.nix
    ./services/jellyfin.nix
    ./services/forgejo.nix
    ./services/miniflux.nix
  ];

  # Pass domain to all modules
  _module.args.domain = domain;
}
```

## 3. SSL Certificates (Let's Encrypt)

Create `modules/blocks/ssl.nix`:

```nix
{ config, lib, domain, ... }:
{
  shb.certs.certs.letsencrypt.${domain} = {
    inherit domain;
    group = "nginx";
    reloadServices = [ "nginx.service" ];
    dnsProvider = "namecheap";
    adminEmail = "admin@${domain}";
    credentialsFile = config.sops.secrets."namecheap/credentials".path;
    additionalEnvironment = {
      NAMECHEAP_HTTP_TIMEOUT = "60";
      NAMECHEAP_PROPAGATION_TIMEOUT = "3600";
    };
    extraDomains = [
      "auth.${domain}"
      "ldap.${domain}"
      "cloud.${domain}"
      "vault.${domain}"
      "git.${domain}"
      "media.${domain}"
      "rss.${domain}"
      "grafana.${domain}"
    ];
  };

  sops.secrets."namecheap/credentials" = {
    sopsFile = ../homelab/secrets.yaml;
  };
}
```

## 4. LDAP (User Management)

Create `modules/blocks/ldap.nix`:

```nix
{ config, lib, domain, ... }:
{
  shb.lldap = {
    enable = true;
    subdomain = "ldap";
    inherit domain;
    dcdomain = "dc=knightoffaith,dc=systems";
    ldapPort = 3890;
    webUIListenPort = 17170;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    jwtSecret.result = config.shb.sops.secrets."lldap/jwt_secret".result;
    ldapUserPassword.result = config.shb.sops.secrets."lldap/user_password".result;
    
    # Restrict LDAP UI to local network
    restrictAccessIPRange = "192.168.12.0/24";
    
    # Create user groups
    ensureGroups = {
      users = {};
      admins = {};
      media = {};
    };
  };

  shb.sops.secrets."lldap/jwt_secret".request = config.shb.lldap.jwtSecret.request;
  shb.sops.secrets."lldap/user_password".request = config.shb.lldap.ldapUserPassword.request;
}
```

## 5. Authelia (SSO)

Create `modules/blocks/authelia.nix`:

```nix
{ config, lib, domain, ... }:
{
  shb.authelia = {
    enable = true;
    subdomain = "auth";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};

    ldapHostname = "127.0.0.1";
    ldapPort = config.shb.lldap.ldapPort;
    dcdomain = config.shb.lldap.dcdomain;

    smtp = {
      host = "smtp.mailgun.org";  # Or your SMTP provider
      port = 587;
      username = "postmaster@mg.${domain}";
      from_address = "auth@${domain}";
      password.result = config.shb.sops.secrets."authelia/smtp_password".result;
    };

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
  shb.sops.secrets."authelia/ldap_admin_password" = {
    request = config.shb.authelia.secrets.ldapAdminPassword.request;
    settings.key = "lldap/user_password";  # Reuse LDAP admin password
  };
  shb.sops.secrets."authelia/session_secret".request = config.shb.authelia.secrets.sessionSecret.request;
  shb.sops.secrets."authelia/storage_encryption_key".request = config.shb.authelia.secrets.storageEncryptionKey.request;
  shb.sops.secrets."authelia/hmac_secret".request = config.shb.authelia.secrets.identityProvidersOIDCHMACSecret.request;
  shb.sops.secrets."authelia/private_key".request = config.shb.authelia.secrets.identityProvidersOIDCIssuerPrivateKey.request;
  shb.sops.secrets."authelia/smtp_password".request = config.shb.authelia.smtp.password.request;
}
```

## 6. Example Service: Nextcloud

Create `modules/services/nextcloud.nix`:

```nix
{ config, lib, domain, ... }:
{
  shb.nextcloud = {
    enable = true;
    subdomain = "cloud";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    adminPassword.result = config.shb.sops.secrets."nextcloud/admin_password".result;
    
    apps.ldap = {
      enable = true;
      host = "127.0.0.1";
      port = config.shb.lldap.ldapPort;
      dcdomain = config.shb.lldap.dcdomain;
      adminPassword.result = config.shb.sops.secrets."nextcloud/ldap/admin_password".result;
    };
    
    apps.sso = {
      enable = true;
      endpoint = "https://auth.${domain}";
      secret.result = config.shb.sops.secrets."nextcloud/sso/secret".result;
      secretForAuthelia.result = config.shb.sops.secrets."nextcloud/sso/secretForAuthelia".result;
    };
  };

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
```

## 7. Deploy Services

```bash
# From your local machine
nix run .#deploy-homelab

# Or with Colmena
nix run .#colmena -- apply
```

## 8. Access Services

After deployment:

| Service | URL |
|---------|-----|
| LDAP Admin | https://ldap.knightoffaith.systems |
| Auth (SSO) | https://auth.knightoffaith.systems |
| Nextcloud | https://cloud.knightoffaith.systems |
| Vaultwarden | https://vault.knightoffaith.systems |
| Jellyfin | https://media.knightoffaith.systems |
| Forgejo | https://git.knightoffaith.systems |
| Miniflux | https://rss.knightoffaith.systems |
| Grafana | https://grafana.knightoffaith.systems |

## Next Step

→ [04-CUSTOM-SERVICES.md](04-CUSTOM-SERVICES.md)

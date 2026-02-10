{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
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
    
    # Security: Restrict LDAP UI to local network only
    restrictAccessIPRange = "192.168.12.0/24";
    
    # User groups
    ensureGroups = {
      users = {};
      admins = {};
      media = {};       # For Jellyfin access
      nextcloud = {};   # For Nextcloud access
      git = {};         # For Forgejo access
    };
    
    # Example: Create initial admin user
    # Uncomment and configure after first deploy
    # ensureUsers = {
    #   admin = {
    #     email = "admin@${domain}";
    #     displayName = "Administrator";
    #     groups = [ "admins" "users" ];
    #     password.result = config.shb.sops.secrets."lldap/admin_password".result;
    #   };
    # };
  };

  # SOPS secrets for LLDAP
  shb.sops.secrets."lldap/jwt_secret".request = config.shb.lldap.jwtSecret.request;
  shb.sops.secrets."lldap/user_password".request = config.shb.lldap.ldapUserPassword.request;
}

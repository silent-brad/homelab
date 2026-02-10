{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  # Let's Encrypt SSL certificates via DNS challenge (Namecheap)
  shb.certs.certs.letsencrypt.${domain} = {
    inherit domain;
    group = "nginx";
    reloadServices = [ "nginx.service" ];
    
    # Namecheap DNS provider for ACME
    dnsProvider = "namecheap";
    adminEmail = "admin@${domain}";
    credentialsFile = config.sops.secrets."namecheap/credentials".path;
    
    additionalEnvironment = {
      NAMECHEAP_HTTP_TIMEOUT = "60";
      NAMECHEAP_PROPAGATION_TIMEOUT = "3600";
    };

    # All subdomains to include in the certificate
    extraDomains = [
      "auth.${domain}"
      "ldap.${domain}"
      "cloud.${domain}"
      "vault.${domain}"
      "git.${domain}"
      "media.${domain}"
      "rss.${domain}"
      "grafana.${domain}"
      "prometheus.${domain}"
    ];
  };

  sops.secrets."namecheap/credentials" = {
    sopsFile = ../../homelab/secrets.yaml;
    mode = "0400";
  };
}

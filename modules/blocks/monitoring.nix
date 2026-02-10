{ config, lib, ... }:
let
  domain = "knightoffaith.systems";
in
{
  shb.monitoring = {
    enable = true;
    subdomain = "grafana";
    inherit domain;
    ssl = config.shb.certs.certs.letsencrypt.${domain};
    
    # Grafana admin password
    adminPassword.result = config.shb.sops.secrets."grafana/admin_password".result;
    
    # Enable Prometheus metrics collection
    prometheus = {
      enable = true;
    };
    
    # Enable Loki for log aggregation
    loki = {
      enable = true;
    };
  };

  shb.sops.secrets."grafana/admin_password".request = config.shb.monitoring.adminPassword.request;
}

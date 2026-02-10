{ config, lib, pkgs, ... }:
let
  domain = "knightoffaith.systems";
in
{
  imports = [
    ./blocks/ssl.nix
    ./blocks/ldap.nix
    ./blocks/authelia.nix
    ./blocks/monitoring.nix
    ./services/nextcloud.nix
    ./services/vaultwarden.nix
    ./services/jellyfin.nix
    ./services/forgejo.nix
    ./services/miniflux.nix
  ];

  # Pass domain to all modules via module args
  _module.args.domain = domain;
}

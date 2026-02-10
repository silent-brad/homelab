# NixOS Homelab with Skarabox + Self Host Blocks

This repository contains the configuration for a NixOS-based homelab server using:
- **[Skarabox](https://github.com/ibizaman/skarabox)** - Opinionated NixOS installer with ZFS encryption
- **[Self Host Blocks](https://github.com/ibizaman/selfhostblocks)** - Unified service configuration

## Domain

- **Domain**: knightoffaith.systems (Namecheap)

## Quick Start

1. Follow [01-PREREQUISITES.md](docs/01-PREREQUISITES.md) to prepare your environment
2. Follow [02-INSTALLATION.md](docs/02-INSTALLATION.md) to install NixOS with Skarabox
3. Follow [03-SERVICES.md](docs/03-SERVICES.md) to configure services
4. Follow [04-CUSTOM-SERVICES.md](docs/04-CUSTOM-SERVICES.md) for services outside SHB (e.g., Miniflux)

## Directory Structure

```
homelab/
├── docs/                    # Step-by-step guides
├── scripts/                 # Nushell automation scripts
├── homelab/                 # Host configuration (created by Skarabox)
│   ├── configuration.nix    # Main NixOS config
│   ├── services/            # Modular service configs
│   ├── secrets.yaml         # SOPS encrypted secrets
│   └── facter.json          # Hardware config
└── flake.nix               # Nix flake entry point
```

## Services

Self Host Blocks provides these services out of the box:
- Nextcloud (Documents/Files)
- Vaultwarden (Passwords)
- Jellyfin (Media)
- Forgejo (Git hosting)
- Home-Assistant (Automation)
- Monitoring (Grafana/Prometheus/Loki)
- And more...

Custom services added:
- Miniflux (RSS Reader)

## Commands

```bash
# Deploy changes
nix run .#deploy-homelab

# SSH into server
ssh -p 2222 skarabox@homelab.knightoffaith.systems

# Unlock root partition after reboot
ssh -p 2223 root@homelab.knightoffaith.systems
```

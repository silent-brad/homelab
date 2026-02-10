# Quick Start Guide

This is a condensed version of the setup process. See individual docs for details.

## TL;DR Setup Steps

```bash
# 1. Bootstrap (from your local machine)
cd ~/homelab
nix run github:ibizaman/skarabox?ref=v1.4.0

# 2. Copy your SSH public key
cp ~/.ssh/id_ed25519.pub homelab/ssh.pub

# 3. Edit configuration
# Update homelab/configuration.nix with:
#   - Your disk devices (check with fdisk -l on beacon)
#   - Your static IP and gateway
#   - Your timezone

# 4. Edit flake.nix
# Update: ip = "192.168.12.137"

# 5. Generate known_hosts
nix run .#homelab-generateKnownHosts

# 6. Create secrets
cp scripts/secrets-template.yaml homelab/secrets.yaml
# Generate secrets and edit:
nix run nixpkgs#openssl -- rand -hex 64  # for each secret
sops homelab/secrets.yaml

# 7. Build beacon USB
nix build .#homelab-beacon
sudo dd if=./result/iso/beacon.iso of=/dev/sdX bs=4M status=progress

# 8. Boot server from USB, then run:
nix run .#homelab-facter > homelab/facter.json
git add homelab/facter.json
nix run .#homelab-install

# 9. After reboot, unlock:
ssh -p 2223 root@192.168.12.137

# 10. Deploy services:
nix run .#deploy-homelab
```

## DNS Setup (Namecheap)

| Type | Host | Value |
|------|------|-------|
| A | @ | YOUR_PUBLIC_IP |
| A | * | YOUR_PUBLIC_IP |

## Router Port Forwarding

| Port | Purpose |
|------|---------|
| 80 → 80 | HTTP/ACME |
| 443 → 443 | HTTPS |
| 2222 → 2222 | SSH |
| 2223 → 2223 | Boot SSH |

## Service URLs

After deployment, access at:
- https://auth.knightoffaith.systems (SSO)
- https://ldap.knightoffaith.systems (User management)
- https://cloud.knightoffaith.systems (Nextcloud)
- https://vault.knightoffaith.systems (Vaultwarden)
- https://media.knightoffaith.systems (Jellyfin)
- https://git.knightoffaith.systems (Forgejo)
- https://rss.knightoffaith.systems (Miniflux)
- https://grafana.knightoffaith.systems (Monitoring)

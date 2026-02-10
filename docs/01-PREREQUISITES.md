# Prerequisites

## Requirements

- A machine with Nix installed (for building the installer)
- USB drive (4GB+) for the Skarabox beacon
- Your server with disk(s) ready to be **WIPED**

## 1. Install Nix (if not already installed)

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## 2. Enable Flakes

Add to `~/.config/nix/nix.conf` or `/etc/nix/nix.conf`:
```
experimental-features = nix-command flakes
```

## 3. Set Up Namecheap DNS

Before installation, configure your domain `knightoffaith.systems`:

### DNS Records (in Namecheap Dashboard)

| Type | Host | Value | TTL |
|------|------|-------|-----|
| A | @ | YOUR_PUBLIC_IP | Auto |
| A | * | YOUR_PUBLIC_IP | Auto |

Find your public IP: https://api.ipify.org/

### Enable Namecheap API Access

**Note**: Namecheap requires one of:
- $50+ account balance
- 20+ domains
- $50+ purchases in last 2 years

1. Go to Profile → Tools → API Access
2. Enable API Access
3. Whitelist your IP address
4. Note your API Key

Create credentials file for later:
```bash
mkdir -p ~/.secrets
cat > ~/.secrets/namecheap-credentials <<EOF
NAMECHEAP_API_USER=your_username
NAMECHEAP_API_KEY=your_api_key
EOF
chmod 600 ~/.secrets/namecheap-credentials
```

## 4. Generate SSH Key (if needed)

```bash
ssh-keygen -t ed25519 -C "homelab" -f ~/.ssh/homelab
```

## 5. Router Configuration

Prepare to forward these ports to your server's static IP:

| External Port | Internal Port | Purpose |
|---------------|---------------|---------|
| 80 | 80 | HTTP (ACME challenges) |
| 443 | 443 | HTTPS |
| 2222 | 2222 | SSH access |
| 2223 | 2223 | SSH boot unlock |

## Next Step

→ [02-INSTALLATION.md](02-INSTALLATION.md)

# Normal Operations

## Daily Operations

### SSH Access

```bash
# Normal SSH access
ssh -p 2222 skarabox@192.168.12.137

# Or using domain (after DNS is configured)
ssh -p 2222 skarabox@homelab.knightoffaith.systems
```

### Unlocking After Reboot

After a power outage or reboot, the ZFS root pool needs decryption:

```bash
ssh -p 2223 root@192.168.12.137
# Enter ZFS passphrase
```

The server will then boot normally.

## Deploying Changes

### From Local Machine

```bash
# Using deploy-rs
nix run .#deploy-homelab

# Or using Colmena
nix run .#colmena -- apply
```

### Directly on Server

```bash
ssh -p 2222 skarabox@192.168.12.137
sudo nixos-rebuild switch --flake github:yourusername/homelab#homelab
```

## Service Management

### Check Service Status

```bash
# All services
systemctl list-units --type=service --state=running

# Specific service
systemctl status nginx
systemctl status lldap
systemctl status authelia-auth.knightoffaith.systems
systemctl status nextcloud-setup
systemctl status miniflux
```

### View Logs

```bash
# Real-time logs
journalctl -u nginx -f
journalctl -u miniflux -f

# Recent logs
journalctl -u authelia-auth.knightoffaith.systems --since "1 hour ago"
```

### Restart Services

```bash
sudo systemctl restart nginx
sudo systemctl restart miniflux
```

## Backup & Restore

Self Host Blocks provides integrated backup via BorgBackup or Restic.

### Check Backup Status

```bash
# List backup jobs
systemctl list-timers | grep backup
```

### Manual Backup

```bash
# Trigger backup manually
sudo systemctl start borgbackup-job-<service>.service
```

## SSL Certificates

### Check Certificate Status

```bash
# View certificate expiry
sudo openssl x509 -in /var/lib/acme/knightoffaith.systems/cert.pem -noout -dates

# Force certificate renewal
sudo systemctl start acme-knightoffaith.systems.service
```

### Debug Certificate Issues

```bash
journalctl -u acme-knightoffaith.systems.service
```

## User Management (LDAP)

Access the LLDAP web UI at https://ldap.knightoffaith.systems

Default admin user: `admin`
Password: The one in `lldap/user_password` secret

### CLI User Management

```bash
# SSH into server
ssh -p 2222 skarabox@192.168.12.137

# Use lldap CLI (if available)
# Or manage via web UI
```

## Monitoring

Access Grafana at https://grafana.knightoffaith.systems

Default dashboards include:
- System metrics (CPU, memory, disk)
- Nginx access logs
- Service-specific dashboards

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u <service> -n 100

# Check configuration
nixos-rebuild dry-build --flake .#homelab

# Verify secrets are decrypted
sudo ls -la /run/secrets/
```

### SSL Issues

```bash
# Check ACME status
systemctl status acme-knightoffaith.systems

# Test DNS
nslookup knightoffaith.systems
nslookup cloud.knightoffaith.systems
```

### LDAP Issues

```bash
# Check LLDAP status
systemctl status lldap

# Test LDAP connection
ldapsearch -x -H ldap://127.0.0.1:3890 -b "dc=knightoffaith,dc=systems"
```

### Nginx Issues

```bash
# Test configuration
sudo nginx -t

# Check logs
sudo tail -f /var/log/nginx/error.log
```

## Updates

### Update Flake Inputs

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input selfhostblocks

# Deploy updates
nix run .#deploy-homelab
```

### Rollback

```bash
# On server
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB menu
```

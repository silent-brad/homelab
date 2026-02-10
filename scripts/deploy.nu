#!/usr/bin/env nu

# Deployment helper script
# Run with: nu scripts/deploy.nu

def main [] {
    print "Homelab Deployment"
    print "=================="
    print ""
    print "Commands:"
    print "  nu scripts/deploy.nu status    - Check server status"
    print "  nu scripts/deploy.nu deploy    - Deploy configuration"
    print "  nu scripts/deploy.nu ssh       - SSH into server"
    print "  nu scripts/deploy.nu unlock    - Unlock boot partition"
    print "  nu scripts/deploy.nu logs      - View service logs"
    print ""
}

# Server configuration
let server_ip = "192.168.12.137"
let ssh_port = 2222
let boot_port = 2223
let username = "skarabox"

# Check server status
def "main status" [] {
    print $"Checking server at ($server_ip)..."
    
    # Ping test
    let ping = (ping -c 1 $server_ip | complete)
    if $ping.exit_code == 0 {
        print "✅ Server is reachable"
    } else {
        print "❌ Server is not reachable"
        return
    }
    
    # SSH test
    let ssh_check = (ssh -p $ssh_port -o ConnectTimeout=5 -o BatchMode=yes $"($username)@($server_ip)" "echo ok" | complete)
    if $ssh_check.exit_code == 0 {
        print "✅ SSH connection working"
    } else {
        print "⚠️  SSH connection failed (may need unlock)"
    }
}

# Deploy configuration
def "main deploy" [] {
    print "Deploying to homelab..."
    nix run ".#deploy-homelab"
}

# SSH into server
def "main ssh" [] {
    ssh -p $ssh_port $"($username)@($server_ip)"
}

# Unlock boot partition
def "main unlock" [] {
    print "Connecting to boot SSH to unlock root partition..."
    print "Enter ZFS passphrase when prompted."
    ssh -p $boot_port $"root@($server_ip)"
}

# View service logs
def "main logs" [service?: string] {
    if ($service | is-empty) {
        print "Usage: nu scripts/deploy.nu logs <service>"
        print ""
        print "Available services:"
        print "  nginx, lldap, authelia, nextcloud, vaultwarden"
        print "  jellyfin, forgejo, miniflux, grafana, prometheus"
        return
    }
    
    ssh -p $ssh_port $"($username)@($server_ip)" $"sudo journalctl -u ($service) -f"
}

# Check service status
def "main services" [] {
    print "Checking service status..."
    ssh -p $ssh_port $"($username)@($server_ip)" "systemctl list-units --type=service --state=running | grep -E '(nginx|lldap|authelia|nextcloud|vaultwarden|jellyfin|forgejo|miniflux|grafana|prometheus)'"
}

# Rebuild on server
def "main rebuild" [] {
    print "Rebuilding NixOS configuration on server..."
    ssh -p $ssh_port $"($username)@($server_ip)" "sudo nixos-rebuild switch"
}

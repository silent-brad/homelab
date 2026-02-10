#!/usr/bin/env nu

# Homelab Setup Script
# Run with: nu scripts/setup.nu

def main [] {
    print "🏠 NixOS Homelab Setup"
    print "====================="
    print ""
    
    let steps = [
        "check-prereqs"
        "generate-secrets"
        "configure"
        "build-beacon"
    ]
    
    print "Available commands:"
    print "  nu scripts/setup.nu check      - Check prerequisites"
    print "  nu scripts/setup.nu secrets    - Generate all secrets"
    print "  nu scripts/setup.nu beacon     - Build USB beacon ISO"
    print "  nu scripts/setup.nu install    - Run installation"
    print "  nu scripts/setup.nu deploy     - Deploy configuration"
    print ""
}

# Check prerequisites
def "main check" [] {
    print "Checking prerequisites..."
    
    # Check nix
    let nix_version = (do { nix --version } | complete)
    if $nix_version.exit_code != 0 {
        print "❌ Nix is not installed"
        print "  Install with: curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
        return
    }
    print $"✅ Nix: ($nix_version.stdout | str trim)"
    
    # Check flakes
    let flake_check = (do { nix flake --help } | complete)
    if $flake_check.exit_code != 0 {
        print "❌ Flakes not enabled"
        print "  Add to ~/.config/nix/nix.conf: experimental-features = nix-command flakes"
        return
    }
    print "✅ Flakes enabled"
    
    # Check SSH key
    let ssh_key = "~/.ssh/homelab.pub" | path expand
    if ($ssh_key | path exists) {
        print $"✅ SSH key exists: ($ssh_key)"
    } else {
        print "⚠️  No SSH key found at ~/.ssh/homelab.pub"
        print "  Generate with: ssh-keygen -t ed25519 -C 'homelab' -f ~/.ssh/homelab"
    }
    
    # Check sops
    let sops_check = (do { which sops } | complete)
    if $sops_check.exit_code != 0 {
        print "⚠️  SOPS not in PATH (will use nix run)"
    } else {
        print "✅ SOPS available"
    }
    
    print ""
    print "All checks complete!"
}

# Generate secrets
def "main secrets" [] {
    print "Generating secrets..."
    
    let secrets_dir = "homelab"
    mkdir $secrets_dir
    
    # Generate random hex secrets
    def gen_hex [length: int = 64] {
        (nix run nixpkgs#openssl -- rand -hex $length | complete).stdout | str trim
    }
    
    print "Generating random secrets..."
    
    let secrets = {
        "lldap/jwt_secret": (gen_hex 64)
        "lldap/user_password": (gen_hex 32)
        "authelia/jwt_secret": (gen_hex 64)
        "authelia/session_secret": (gen_hex 64)
        "authelia/storage_encryption_key": (gen_hex 64)
        "authelia/hmac_secret": (gen_hex 64)
        "nextcloud/sso/secret": (gen_hex 64)
        "vaultwarden/sso/secret": (gen_hex 64)
        "forgejo/sso/secret": (gen_hex 64)
        "jellyfin/sso/secret": (gen_hex 64)
        "miniflux/oauth_secret": (gen_hex 64)
        "grafana/admin_password": (gen_hex 32)
    }
    
    print $"Generated ($secrets | length) secrets"
    print ""
    print "⚠️  You still need to manually add:"
    print "  - homelab/user/hashedPassword (run: mkpasswd -m sha-512)"
    print "  - namecheap/credentials"
    print "  - authelia/private_key (RSA key)"
    print "  - authelia/smtp_password"
    print "  - miniflux/admin_credentials"
    print ""
    print "Edit secrets with: sops homelab/secrets.yaml"
}

# Build beacon ISO
def "main beacon" [] {
    print "Building USB beacon ISO..."
    nix build ".#homelab-beacon"
    print ""
    print "✅ ISO built: ./result/iso/beacon.iso"
    print ""
    print "Write to USB with:"
    print "  sudo dd if=./result/iso/beacon.iso of=/dev/sdX bs=4M status=progress"
}

# Run installation
def "main install" [] {
    print "⚠️  This will ERASE ALL DATA on the target server!"
    print ""
    
    let confirm = (input "Type 'yes' to continue: ")
    if $confirm != "yes" {
        print "Aborted."
        return
    }
    
    print "Generating hardware config..."
    nix run ".#homelab-facter" | save -f homelab/facter.json
    
    print "Running installation..."
    nix run ".#homelab-install"
}

# Deploy configuration
def "main deploy" [] {
    print "Deploying configuration to homelab..."
    nix run ".#deploy-homelab"
}

# Generate known hosts
def "main known-hosts" [] {
    print "Generating known_hosts file..."
    nix run ".#homelab-generateKnownHosts"
    print "✅ Generated homelab/known_hosts"
}

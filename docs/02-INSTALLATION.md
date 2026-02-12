# Installation

## 1. Bootstrap Skarabox

From your local machine (not the server):

```bash
cd ~/homelab  # or wherever you cloned this repo
nix run github:ibizaman/skarabox?ref=v1.4.0
```

This will:
- Ask for the admin password
- Generate secrets (SSH keys, SOPS keys)
- Create the `homelab` directory structure

The hostname will match your directory name. Rename if needed before running.

## 2. Configure Your Server

Edit `homelab/configuration.nix`:

```nix
{ lib, config, ... }:
let
  inherit (lib) mkMerge;
  domain = "knightoffaith.systems";
in
{
  imports = [
    ../modules/services.nix
  ];

  config = mkMerge [
    # Skarabox config
    {
      skarabox.hostname = "homelab";
      skarabox.username = "skarabox";
      skarabox.hashedPasswordFile = config.sops.secrets."homelab/user/hashedPassword".path;
      skarabox.facter-config = ./facter.json;

      # Update these based on `fdisk -l` output on USB stick
      skarabox.disks.rootPool = {
        disk1 = "/dev/nvme0n1";  # Your primary SSD
        disk2 = null;            # Set if you have a second SSD for mirror
        reservation = "200G";    # ~10% of 2TB
      };
      skarabox.disks.dataPool = {
        enable = false;  # You have one disk, disable data pool
        disk1 = null;
        disk2 = null;
        reservation = "10G";
      };

      skarabox.boot.sshPort = 2223;
      skarabox.sshPort = 2222;
      skarabox.sshAuthorizedKey = ./ssh.pub;
      skarabox.hostId = null;

      sops.defaultSopsFile = ./secrets.yaml;
      sops.age = {
        sshKeyPaths = [ "/boot/host_key" ];
      };

      sops.secrets."homelab/user/hashedPassword" = {
        neededForUsers = true;
      };
    }

    # Static IP (recommended for homelab)
    {
      skarabox.staticNetwork = {
        ip = "192.168.12.137";   # Your server's IP
        gateway = "192.168.12.1"; # Your router
      };
      skarabox.disableNetworkSetup = false;
    }
  ];
}
```

## 3. Configure flake.nix

Update the IP in `flake.nix`:

```nix
skarabox.hosts = {
  homelab = let
    system = "x86_64-linux";
  in {
    nixpkgs = inputs.selfhostblocks.lib.${system}.patchedNixpkgs;
    inherit system;
    hostKeyPub = ./homelab/host_key.pub;
    ip = "192.168.12.137";  # Your server's static IP
    sshPort = 2222;
    sshBootPort = 2223;
    knownHosts = ./homelab/known_hosts;
    # ... rest of config
  };
};
```

## 4. Generate Known Hosts

```bash
nix run .#homelab-gen-knownhosts-file
```

## 5. Create Bootable USB (On-Premise)

```bash
# Build the ISO
nix build .#homelab-beacon

# Write to USB (replace /dev/sdX with your USB device)
# WARNING: This erases the USB drive!
sudo dd if=./result/iso/beacon.iso of=/dev/sdX bs=4M status=progress
sync
```

## 6. Boot Server from USB

1. Plug USB into your server
2. Boot from USB (usually F12 or DEL to access boot menu)
3. The beacon will boot and show its IP address
4. Run `skarabox-help` on the beacon for connection info

## 7. Generate Hardware Config

From your local machine:

```bash
#nix run .#homelab-facter > homelab/facter.json
sudo nix run nixpkgs#nixos-facter -- -o homelab/facter.json
git add homelab/facter.json
```

## 8. Run Installation

```bash
nix run .#homelab-install
```

**This will ERASE all data on the server's disks!**

The server will reboot automatically into NixOS.

## 9. First Boot - Unlock Root Partition

After reboot, unlock the encrypted root partition:

```bash
ssh -p 2223 root@192.168.12.137
# Enter the ZFS passphrase when prompted
```

## 10. Verify Installation

```bash
ssh -p 2222 skarabox@192.168.12.137
```

## Next Step

→ [03-SERVICES.md](03-SERVICES.md)

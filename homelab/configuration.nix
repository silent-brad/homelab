{ lib, config, pkgs, ... }:
let
  inherit (lib) mkMerge;
  domain = "knightoffaith.systems";
in
{
  imports = [
    ../modules/services.nix
  ];

  options = {
  };

  config = mkMerge [
    # ============================================
    # Skarabox Core Configuration
    # ============================================
    {
      skarabox.hostname = "homelab";
      skarabox.username = "skarabox";
      skarabox.hashedPasswordFile = config.sops.secrets."homelab/user/hashedPassword".path;
      skarabox.facter-config = ./facter.json;

      # Disk configuration - UPDATE BASED ON `fdisk -l` OUTPUT
      # Your server has a single 2TB disk
      skarabox.disks.rootPool = {
        disk1 = "/dev/nvme0n1";  # Primary disk
        disk2 = null;            # No mirror (single disk)
        reservation = "200G";    # ~10% of 2TB for ZFS
      };
      
      skarabox.disks.dataPool = {
        enable = false;  # Disable separate data pool (single disk setup)
        disk1 = null;
        disk2 = null;
        reservation = "10G";
      };

      # SSH ports (non-standard for security)
      skarabox.boot.sshPort = 2223;
      skarabox.sshPort = 2222;
      skarabox.sshAuthorizedKey = ./ssh.pub;
      skarabox.hostId = null;

      # Hardware detection (auto-populated by nixos-facter)
      # Uncomment if drivers are missing:
      # boot.initrd.availableKernelModules = [ "r8169" ];
      # hardware.enableAllHardware = true;

      # SOPS secrets configuration
      sops.defaultSopsFile = ./secrets.yaml;
      sops.age = {
        sshKeyPaths = [ "/boot/host_key" ];
      };

      sops.secrets."homelab/user/hashedPassword" = {
        neededForUsers = true;
      };
    }

    # ============================================
    # Network Configuration (Static IP)
    # ============================================
    {
      skarabox.staticNetwork = {
        ip = "192.168.12.137";
        gateway = "192.168.12.1";  # UPDATE: Your router's IP
      };
      skarabox.disableNetworkSetup = false;
    }

    # ============================================
    # System Configuration
    # ============================================
    {
      time.timeZone = "America/New_York";  # UPDATE: Your timezone
      
      environment.systemPackages = with pkgs; [
        vim
        htop
        tmux
        git
        curl
        wget
        jq
        tree
      ];

      # Enable firewall with required ports
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ 
          80    # HTTP
          443   # HTTPS
          2222  # SSH
          2223  # SSH boot
        ];
      };
    }

    # ============================================
    # Domain Configuration
    # ============================================
    {
      # Make domain available to all modules
      _module.args.domain = domain;
    }
  ];
}

{ config, lib, pkgs, ... }:

let
  # WireGuard TUI package
  wg-tui = pkgs.rustPlatform.buildRustPackage rec {
    pname = "wg-tui";
    version = "0.1.0";
    
    src = /home/alice/rotko/wg-tui/wg-tui;
    
    # You'll need to replace this with actual hash after first build attempt
    cargoHash = lib.fakeHash;
    
    nativeBuildInputs = with pkgs; [ pkg-config ];
    buildInputs = with pkgs; [ openssl ];
    
    doCheck = false;
    
    meta = with lib; {
      description = "TUI for managing WireGuard configurations";
      license = licenses.mit;
    };
  };

  # WireGuard configuration
  wgConfigDir = "/etc/wireguard";
  wgKeysDir = "/root/wireguard-keys";
in
{
  # Enable nftables explicitly
  networking.nftables = {
    enable = true;
    
    # Modern nftables ruleset for WireGuard
    ruleset = ''
      table inet wireguard {
        chain forward {
          type filter hook forward priority 0; policy accept;
          
          # Allow forwarding from/to WireGuard interfaces
          iifname "wg0" accept
          oifname "wg0" accept
          
          # Connection tracking for established connections
          ct state established,related accept
        }
        
        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;
          
          # NAT for WireGuard clients (IPv4)
          ip saddr 10.100.0.0/24 oifname != "wg0" masquerade
          
          # NAT for WireGuard clients (IPv6)
          ip6 saddr fd42:42:42::/64 oifname != "wg0" masquerade
        }
      }
      
      # Additional security table
      table inet filter {
        chain input {
          type filter hook input priority 0; policy accept;
          
          # Allow WireGuard
          udp dport 51820 accept
          
          # Allow established connections
          ct state established,related accept
          
          # Allow loopback
          iif lo accept
          
          # Rate limiting for WireGuard handshakes
          udp dport 51820 limit rate 10/second accept
        }
      }
    '';
  };

  # WireGuard interfaces
  networking.wireguard = {
    enable = true;
    
    interfaces = {
      # Server interface
      wg0 = {
        privateKeyFile = "${wgKeysDir}/wg0.key";
        listenPort = 51820;
        
        # Server IPs
        ips = [ 
          "10.100.0.1/24" 
          "fd42:42:42::1/64" 
        ];
        
        # Use nftables for setup/teardown (cleaner than iptables)
        postSetup = ''
          # Ensure nftables rules are loaded
          ${pkgs.nftables}/bin/nft -f - <<NFT
            add table inet wireguard
            add chain inet wireguard forward { type filter hook forward priority 0 \; }
            add chain inet wireguard postrouting { type nat hook postrouting priority srcnat \; }
            add rule inet wireguard forward iifname "wg0" accept
            add rule inet wireguard forward oifname "wg0" accept
            add rule inet wireguard postrouting ip saddr 10.100.0.0/24 oifname != "wg0" masquerade
            add rule inet wireguard postrouting ip6 saddr fd42:42:42::/64 oifname != "wg0" masquerade
          NFT
        '';
        
        postShutdown = ''
          # Clean up nftables rules
          ${pkgs.nftables}/bin/nft delete table inet wireguard 2>/dev/null || true
        '';
        
        # Peers will be added dynamically
        peers = [];
      };
    };
  };

  # Enable IP forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.rp_filter" = 0;
    "net.ipv4.conf.all.rp_filter" = 0;
  };

  # Firewall configuration (uses nftables backend)
  networking.firewall = {
    enable = true;
    
    # WireGuard port
    allowedUDPPorts = [ 51820 ];
    
    # Trust WireGuard interface
    trustedInterfaces = [ "wg0" ];
    
    # Use nftables backend
    package = pkgs.nftables;
    
    # Log dropped packets for debugging
    logRefusedConnections = false;
    logRefusedPackets = false;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    wireguard-tools
    nftables  # nft command
    wg-tui    # Our custom TUI
    qrencode  # QR codes for mobile
    jq        # JSON processing for scripts
  ];

  # Create directories and initial setup
  system.activationScripts.wireguardSetup = ''
    # Create keys directory
    mkdir -p ${wgKeysDir}
    chmod 700 ${wgKeysDir}
    
    # Create config directory structure
    mkdir -p ${wgConfigDir}/clients
    chmod 755 ${wgConfigDir}
    chmod 700 ${wgConfigDir}/clients
    
    # Generate server key if needed
    if [ ! -f ${wgKeysDir}/wg0.key ]; then
      echo "Generating WireGuard server key..."
      ${pkgs.wireguard-tools}/bin/wg genkey > ${wgKeysDir}/wg0.key
      chmod 600 ${wgKeysDir}/wg0.key
      
      ${pkgs.wireguard-tools}/bin/wg pubkey < ${wgKeysDir}/wg0.key > ${wgKeysDir}/wg0.pub
      chmod 644 ${wgKeysDir}/wg0.pub
      
      echo "Server public key: $(cat ${wgKeysDir}/wg0.pub)"
    fi
  '';

  # Modern shell aliases
  programs.zsh.shellAliases = {
    # nftables management
    nft-list = "sudo nft list ruleset";
    nft-monitor = "sudo nft monitor";
    nft-trace = "sudo nft monitor trace";
    
    # WireGuard management
    wg-status = "sudo wg show";
    wg-ui = "sudo wg-tui";
    wg-peers = "sudo wg show wg0 peers";
    wg-stats = "sudo wg show wg0 transfer";
    
    # Peer management
    wg-add = "sudo /etc/nixos/scripts/wg-add-peer.sh";
    wg-remove = "sudo /etc/nixos/scripts/wg-remove-peer.sh";
    wg-qr = "sudo /etc/nixos/scripts/wg-show-qr.sh";
    
    # Debugging
    wg-debug = "sudo journalctl -u wireguard-wg0 -f";
    nft-debug = "sudo nft -d netlink list ruleset";
  };
}

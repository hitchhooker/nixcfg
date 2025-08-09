#!/usr/bin/env bash
set -euo pipefail

# Configuration
readonly INTERFACE="wg0"
readonly WG_DIR="/etc/wireguard"
readonly KEYS_DIR="/root/wireguard-keys"
readonly CLIENTS_DIR="$WG_DIR/clients"
readonly SUBNET_V4="10.100.0"
readonly SUBNET_V6="fd42:42:42"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $*"; }

get_next_ip() {
    local used_ips
    used_ips=$(sudo wg show "$INTERFACE" dump 2>/dev/null | \
                tail -n +2 | \
                awk -F'\t' '{print $4}' | \
                grep -oE "${SUBNET_V4}\.[0-9]+" | \
                cut -d'.' -f4 | \
                sort -n)
    
    for i in {2..254}; do
        if ! echo "$used_ips" | grep -q "^${i}$"; then
            echo "$i"
            return
        fi
    done
    
    return 1
}

get_server_endpoint() {
    local public_ip
    public_ip=$(curl -s -4 ifconfig.me 2>/dev/null || \
                curl -s -4 icanhazip.com 2>/dev/null || \
                echo "YOUR_SERVER_IP")
    echo "${public_ip}:51820"
}

# Main script
main() {
    log_info "WireGuard Peer Addition Tool"
    echo "=============================="
    
    # Check prerequisites
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Get peer name
    read -rp "Enter peer name (alphanumeric, dash, underscore): " peer_name
    
    # Validate peer name
    if [[ ! "$peer_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_error "Invalid peer name. Use only alphanumeric, dash, and underscore."
        exit 1
    fi
    
    # Check if peer already exists
    if [[ -f "$CLIENTS_DIR/${peer_name}.conf" ]]; then
        log_error "Peer '${peer_name}' already exists"
        exit 1
    fi
    
    # Get next available IP
    log_info "Allocating IP address..."
    next_ip=$(get_next_ip)
    if [[ -z "$next_ip" ]]; then
        log_error "No available IPs in subnet"
        exit 1
    fi
    
    client_ipv4="${SUBNET_V4}.${next_ip}/32"
    client_ipv6="${SUBNET_V6}::${next_ip}/128"
    log_success "Allocated IPs: ${client_ipv4}, ${client_ipv6}"
    
    # Generate keys
    log_info "Generating cryptographic keys..."
    client_private_key=$(wg genkey)
    client_public_key=$(echo "$client_private_key" | wg pubkey)
    preshared_key=$(wg genpsk)
    
    # Get server info
    server_public_key=$(cat "$KEYS_DIR/wg0.pub")
    
    # Get or ask for endpoint
    default_endpoint=$(get_server_endpoint)
    read -rp "Enter server endpoint [${default_endpoint}]: " server_endpoint
    server_endpoint="${server_endpoint:-$default_endpoint}"
    
    # DNS servers
    read -rp "DNS servers [9.9.9.9, 149.112.112.112]: " dns_servers
    dns_servers="${dns_servers:-9.9.9.9, 149.112.112.112}"
    
    # Create client config
    log_info "Creating client configuration..."
    mkdir -p "$CLIENTS_DIR"
    
    cat > "$CLIENTS_DIR/${peer_name}.conf" << EOL
# WireGuard configuration for ${peer_name}
# Generated: $(date -Iseconds)

[Interface]
PrivateKey = ${client_private_key}
Address = ${client_ipv4%/32}/24, ${client_ipv6%/128}/64
DNS = ${dns_servers}
# Optional: uncomment for kill switch
# PostUp = nft add table inet wireguard_killswitch; nft add chain inet wireguard_killswitch output { type filter hook output priority 0 \\; policy drop \\; }; nft add rule inet wireguard_killswitch output oifname "%i" accept; nft add rule inet wireguard_killswitch output oifname "lo" accept
# PostDown = nft delete table inet wireguard_killswitch

[Peer]
PublicKey = ${server_public_key}
PresharedKey = ${preshared_key}
Endpoint = ${server_endpoint}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOL
    
    chmod 600 "$CLIENTS_DIR/${peer_name}.conf"
    
    # Add peer to server
    log_info "Adding peer to server..."
    sudo wg set "$INTERFACE" peer "$client_public_key" \
        preshared-key <(echo "$preshared_key") \
        allowed-ips "${client_ipv4},${client_ipv6}"
    
    # Save configuration
    sudo wg-quick save "$INTERFACE"
    
    # Update nftables if needed
    log_info "Updating nftables rules..."
    sudo nft add rule inet wireguard forward ip saddr "${client_ipv4%/32}" accept 2>/dev/null || true
    sudo nft add rule inet wireguard forward ip daddr "${client_ipv4%/32}" accept 2>/dev/null || true
    
    # Display summary
    echo
    log_success "Peer '${peer_name}' added successfully!"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Client Details:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Name:       ${peer_name}"
    echo "  IPv4:       ${client_ipv4%/32}"
    echo "  IPv6:       ${client_ipv6%/128}"
    echo "  Public Key: ${client_public_key}"
    echo "  Config:     ${CLIENTS_DIR}/${peer_name}.conf"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    echo "To display QR code:"
    echo "  qrencode -t ansiutf8 < ${CLIENTS_DIR}/${peer_name}.conf"
    echo
    echo "To copy config to clipboard:"
    echo "  cat ${CLIENTS_DIR}/${peer_name}.conf | xclip -selection clipboard"
}

main "$@"

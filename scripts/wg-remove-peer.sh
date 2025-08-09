#!/usr/bin/env bash
set -euo pipefail

readonly INTERFACE="wg0"
readonly CLIENTS_DIR="/etc/wireguard/clients"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# List available peers
echo "Available peers:"
echo "================"
for conf in "$CLIENTS_DIR"/*.conf; do
    [[ -f "$conf" ]] || continue
    basename "$conf" .conf
done

echo
read -rp "Enter peer name to remove: " peer_name

conf_file="$CLIENTS_DIR/${peer_name}.conf"
if [[ ! -f "$conf_file" ]]; then
    echo -e "${RED}Peer configuration not found${NC}"
    exit 1
fi

# Extract public key from config
public_key=$(grep -oP 'PublicKey = \K.*' "$conf_file" | tail -1)

if [[ -z "$public_key" ]]; then
    echo -e "${RED}Could not find public key in configuration${NC}"
    exit 1
fi

# Confirm removal
echo -e "${YELLOW}Warning: This will remove peer '${peer_name}'${NC}"
read -rp "Are you sure? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Aborted"
    exit 0
fi

# Remove peer from WireGuard
sudo wg set "$INTERFACE" peer "$public_key" remove

# Save configuration
sudo wg-quick save "$INTERFACE"

# Remove config file
rm -f "$conf_file"

echo -e "${GREEN}Peer '${peer_name}' removed successfully${NC}"

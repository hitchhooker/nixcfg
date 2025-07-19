{ pkgs, ... }:

pkgs.writeShellScriptBin "wifi" ''
 #!/usr/bin/env bash
 
 # Auto-detect interface
 IFACE=$(${pkgs.iproute2}/bin/ip link show | grep -E "wlp|wlan" | head -1 | cut -d: -f2 | tr -d ' ')
 CONF="/etc/wpa_supplicant.conf"
 
 case "''${1:-help}" in
   list|l)
     echo "Available networks:"
     grep -E "^\s*(#\s*)?network=" $CONF -A3 | grep -E "ssid=" | \
       sed 's/.*ssid="\([^"]*\)".*/\1/' | \
       while read ssid; do
         if grep -B1 "ssid=\"$ssid\"" $CONF | grep -q "^network="; then
           echo "[✓] $ssid"
         else
           echo "[ ] $ssid"
         fi
       done
     ;;
     
   enable|e)
     SSID="$2"
     if [ -z "$SSID" ]; then
       echo "Usage: wifi enable SSID"
       exit 1
     fi
     
     # Create temp file
     TMP=$(mktemp)
     awk -v ssid="$SSID" '
       /^#\s*network=\{/ {
         in_block=1
         block=""
       }
       in_block {
         block = block $0 "\n"
         if ($0 ~ "ssid=\"" ssid "\"") {
           found=1
         }
         if (/^\}/) {
           if (found) {
             gsub(/^# /, "", block)
             gsub(/\n# /g, "\n", block)
             printf "%s", block
             found=0
           } else {
             printf "%s", block
           }
           in_block=0
           block=""
           next
         }
       }
       !in_block { print }
     ' $CONF > $TMP
     
     sudo mv $TMP $CONF
     sudo wpa_cli -i $IFACE reconfigure
     echo "Enabled $SSID"
     ;;
     
   disable|d)
     SSID="$2"
     if [ -z "$SSID" ]; then
       echo "Usage: wifi disable SSID"
       exit 1
     fi
     
     # Comment out the network block
     TMP=$(mktemp)
     awk -v ssid="$SSID" '
       /^network=\{/ {
         in_block=1
         block=""
       }
       in_block {
         block = block $0 "\n"
         if ($0 ~ "ssid=\"" ssid "\"") {
           found=1
         }
         if (/^\}/) {
           if (found) {
             gsub(/^/, "# ", block)
             gsub(/\n/g, "\n# ", block)
             sub(/\n# $/, "\n", block)
             printf "%s", block
             found=0
           } else {
             printf "%s", block
           }
           in_block=0
           block=""
           next
         }
       }
       !in_block { print }
     ' $CONF > $TMP
     
     sudo mv $TMP $CONF
     sudo wpa_cli -i $IFACE reconfigure
     echo "Disabled $SSID"
     ;;
     
   scan|s)
     echo "Scanning on $IFACE..."
     wpa_cli -i $IFACE scan >/dev/null
     sleep 2
     echo ""
     printf "%-4s %-25s %s\n" "Signal" "SSID" "Security"
     printf "%s\n" "----------------------------------------"
     wpa_cli -i $IFACE scan_results | grep -v "^bssid" | \
       awk -F'\t' '{
         security = ($4 ~ /WPA2/) ? "WPA2" : ($4 ~ /WPA/) ? "WPA" : ($4 ~ /WEP/) ? "WEP" : "Open"
         printf "%-4s %-25s %s\n", $3"dBm", substr($5,1,25), security
       }' | sort -n | tail -20
     ;;
     
   add|a)
     SSID="$2"
     PASS="$3"
     
     if [ -z "$SSID" ]; then
       echo "Usage: wifi add SSID [password]"
       exit 1
     fi
     
     # Add commented by default
     if [ -n "$PASS" ]; then
       wpa_passphrase "$SSID" "$PASS" | sed 's/^/# /' | sudo tee -a $CONF
     else
       echo -e "# network={\n# \tssid=\"$SSID\"\n# \tkey_mgmt=NONE\n# }" | sudo tee -a $CONF
     fi
     
     echo "Added $SSID (disabled by default, use 'wifi enable $SSID' to activate)"
     ;;
     
   *)
     echo "wifi - manage wpa_supplicant networks"
     echo ""
     echo "Commands:"
     echo "  wifi list              # show all networks ([✓] = enabled)"
     echo "  wifi enable SSID       # uncomment and activate network"
     echo "  wifi disable SSID      # comment out network"
     echo "  wifi scan              # scan for available networks"
     echo "  wifi add SSID [pass]   # add new network (disabled by default)"
     echo ""
     echo "Current interface: $IFACE"
     if wpa_cli -i $IFACE status 2>/dev/null | grep -q "ssid="; then
       echo "Connected to: $(wpa_cli -i $IFACE status | grep "^ssid=" | cut -d= -f2)"
     fi
     ;;
 esac
''

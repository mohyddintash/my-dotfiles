#!/bin/bash

# Check if network manager is active
if ! systemctl is-active --quiet NetworkManager; then
    notify-send "NetworkManager is not running!" "Please start NetworkManager to manage Wi-Fi."
    exit 1
fi

# Get the name of the Wi-Fi interface (adjust if yours is different, e.g., wlan0)
WIFI_IFACE=$(nmcli device status | grep wifi | awk '{print $1}')
if [ -z "$WIFI_IFACE" ]; then
    notify-send "No Wi-Fi interface found!" "Ensure your Wi-Fi adapter is recognized."
    exit 1
fi

CONNECTED_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)

declare -A networks
options=""
while IFS= read -r line; do
    SSID=$(echo "$line" | cut -d: -f1)
    SIGNAL=$(echo "$line" | cut -d: -f2)

    if [ -z "$SSID" ] || [ "$SSID" = "--" ]; then
        SSID="<Hidden Network>"
    fi

    if [ "$SSID" = "$CONNECTED_SSID" ]; then
        options+="$SSID ($SIGNAL%) [Connected]\n"
        networks["$SSID ($SIGNAL%) [Connected]"]="$SSID"
    else
        options+="$SSID ($SIGNAL%)\n"
        networks["$SSID ($SIGNAL%)"]="$SSID"
    fi
done < <(nmcli -t -f ssid,signal dev wifi list)

options+="Disconnect\n"

# Use wofi to present the options
chosen=$(echo -e "$options" | wofi -d -p "Select Wi-Fi Network:" -i)

if [ -z "$chosen" ]; then
    exit 0 # User cancelled
fi

if [ "$chosen" = "Disconnect" ]; then
    if [ -n "$CONNECTED_SSID" ]; then
        nmcli device disconnect "$WIFI_IFACE"
        notify-send "Disconnected from Wi-Fi" "$CONNECTED_SSID"
    else
        notify-send "Not connected to any Wi-Fi network."
    fi
else
    # Extract the SSID from the chosen string (remove signal bars and "[Connected]")
    SSID_TO_CONNECT=$(echo "$chosen" | sed -E 's/\s*\([0-9]+%\)\s*\[Connected\]//' | sed -E 's/\s*\([0-9]+%\)//' | sed 's/<Hidden Network>//g' | xargs)

    if [ "$SSID_TO_CONNECT" = "$CONNECTED_SSID" ]; then
        notify-send "Already connected to $SSID_TO_CONNECT"
        exit 0
    fi

    notify-send "Connecting to Wi-Fi..." "$SSID_TO_CONNECT"

    # Check if a connection profile for this SSID already exists
    if nmcli connection show | grep -q "^${SSID_TO_CONNECT}\s"; then
        nmcli connection up "$SSID_TO_CONNECT"
    else
        # This is the line that needs to change!
        # Use --ask to force nmcli to prompt for passwords via its text-based prompt
        nmcli device wifi connect "$SSID_TO_CONNECT" --ask
    fi

    # Wait a bit and check connection status
    sleep 2
    NEW_CONNECTED_SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    if [ "$NEW_CONNECTED_SSID" = "$SSID_TO_CONNECT" ]; then
        notify-send "Connected to Wi-Fi" "$NEW_CONNECTED_SSID"
    else
        notify-send "Failed to connect to Wi-Fi" "$SSID_TO_CONNECT"
        # Optional: Add a notification for secrets not provided
        notify-send "Connection Failed" "Password or other secrets might be required for '$SSID_TO_CONNECT'. Try again or use nm-connection-editor."
    fi
fi



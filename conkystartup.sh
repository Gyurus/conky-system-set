#!/bin/bash
#Conky startup script
sleep 5
echo "Starting Conky setup..."

# Load update module for autoupdate functionality
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/modules/update.sh" ]; then
    source "$SCRIPT_DIR/modules/update.sh"
    
    # Check for updates and auto-update if enabled
    echo "🔍 Checking for automatic updates..."
    check_and_autoupdate "false"
    echo ""
fi

# Detect active interface: prefer Ethernet, fallback to Wi-Fi
iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}')
[ -z "$iface" ] && iface=$(nmcli device status | awk '$3 == "connected" && $2 == "wifi" {print $1; exit}')
[ -z "$iface" ] && iface=$(nmcli device status | awk '$3 == "connected" {print $1; exit}')
[ -z "$iface" ] && iface="enp7s0"  # final fallback: replace "enp7s0" with your actual network interface name if different

# Save the interface
mkdir -p "$HOME/.config/conky"
echo "$iface" > "$HOME/.config/conky/.conky_iface"

# Replace @@IFACE@@ in conky.conf
if [ ! -f "$HOME/.config/conky/conky.conf" ]; then
    echo "Error: Configuration file $HOME/.config/conky/conky.conf not found."
    exit 1
fi
sed -i "s|@@IFACE@@|$iface|g" "$HOME/.config/conky/conky.conf"

# Detect and set GPU temperature command if placeholder exists
if grep -q "@@GPU_TEMP_COMMAND@@" "$HOME/.config/conky/conky.conf"; then
    echo "Updating GPU temperature command..."
    GPU_COMMAND="echo N/A"
    
    # NVIDIA
    if command -v nvidia-smi &> /dev/null; then
        TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
        if [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
            GPU_COMMAND="nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -1 | awk '{print \$1\"°C\"}'"
        fi
    # AMD
    elif ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -l 'amdgpu' &> /dev/null; then
        AMD_HWMON=$(ls /sys/class/hwmon/hwmon*/name | xargs grep -l 'amdgpu' | head -1)
        if [ -f "$(dirname "$AMD_HWMON")/temp1_input" ]; then
            GPU_COMMAND="cat $(dirname "$AMD_HWMON")/temp1_input | awk '{print \$1/1000\"°C\"}'"
        fi
    # Intel
    elif ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -l 'i915' &> /dev/null; then
        INTEL_HWMON=$(ls /sys/class/hwmon/hwmon*/name | xargs grep -l 'i915' | head -1)
        if [ -f "$(dirname "$INTEL_HWMON")/temp1_input" ]; then
            GPU_COMMAND="cat $(dirname "$INTEL_HWMON")/temp1_input | awk '{print \$1/1000\"°C\"}'"
        fi
    fi
    
    # Fallback to thermal zones if no specific GPU sensor found
    if [ "$GPU_COMMAND" = "echo N/A" ]; then
        for thermal in /sys/class/thermal/thermal_zone*/type; do
            if grep -qE 'x86_pkg_temp|pch' "$thermal"; then
                continue # Skip CPU package and PCH temps
            fi
            TEMP=$(cat "$(dirname "$thermal")/temp" 2>/dev/null)
            if [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
                GPU_COMMAND="cat $(dirname "$thermal")/temp | awk '{print \$1/1000\"°C\"}'"
                break
            fi
        done
    fi
    
    # Update GPU temperature command in conky.conf
    escaped_gpu_command=$(printf '%s\n' "$GPU_COMMAND" | sed -e 's/[&\\|]/\\&/g')
    sed -i "s|@@GPU_TEMP_COMMAND@@|$escaped_gpu_command|" "$HOME/.config/conky/conky.conf"
fi

# Launch Conky with final config in background
echo "🚀 Starting Conky in background..."
conky -c "$HOME/.config/conky/conky.conf" &
conky_pid=$!
echo "✅ Conky started successfully (PID: $conky_pid)"
echo "💡 Conky is now running in the background"
echo "🔍 To check if Conky is running: pgrep conky"
echo "🛑 To stop Conky: pkill conky"

#!/bin/bash
#Conky startup script
sleep 5

# Set up logging for autostart debugging
LOG_FILE="$HOME/.config/conky/startup.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > "$LOG_FILE" 2>&1
echo "[$(date)] Starting Conky setup..."

# Determine the installation directory
# First, check if we're running from the installed location
if [ -d "$HOME/.conky-system-set" ]; then
    INSTALL_DIR="$HOME/.conky-system-set"
    echo "[$(date)] Using installed directory: $INSTALL_DIR"
else
    # Fall back to relative path (for development)
    INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "[$(date)] Using relative path directory: $INSTALL_DIR"
fi

# Load monitor-watch module for dynamic monitor detection
if [ -f "$INSTALL_DIR/modules/monitor-watch.sh" ]; then
    source "$INSTALL_DIR/modules/monitor-watch.sh"
    echo "[$(date)] Loaded monitor-watch module"
else
    echo "[$(date)] WARNING: Monitor-watch module not found at $INSTALL_DIR/modules/monitor-watch.sh"
fi

# Load update module for autoupdate functionality
if [ -f "$INSTALL_DIR/modules/update.sh" ]; then
    source "$INSTALL_DIR/modules/update.sh"
    echo "[$(date)] Loaded update module"
    
    # Check for automatic updates and apply if enabled
    echo "[$(date)] Checking for automatic updates..."
    
    # Get auto-update setting (defaults to true if not configured)
    AUTOUPDATE_ENABLED=$(get_update_config "autoupdate_enabled" "true")
    
    if [[ "$AUTOUPDATE_ENABLED" == "true" ]]; then
        echo "[$(date)] Auto-update is ENABLED - checking for updates..."
        # Pass "false" to show output (not silent mode)
        if check_and_autoupdate "false"; then
            echo "[$(date)] ✅ Auto-update check completed"
        else
            echo "[$(date)] ⚠️  Auto-update check finished with warnings"
        fi
    else
        echo "[$(date)] Auto-update is DISABLED - skipping update check"
        echo "[$(date)] To enable auto-updates, run: ./conkyset.sh --enable-autoupdate"
    fi
    echo ""
else
    echo "[$(date)] WARNING: Update module not found at $INSTALL_DIR/modules/update.sh"
fi

# Load weather helpers for location updates
if [ -f "$INSTALL_DIR/modules/weather.sh" ]; then
    source "$INSTALL_DIR/modules/weather.sh"
    echo "[$(date)] Loaded weather module"
else
    echo "[$(date)] WARNING: Weather module not found at $INSTALL_DIR/modules/weather.sh"
fi

# Check for monitor changes and adjust Conky if needed
if [ -f "$HOME/.config/conky/conky.conf" ]; then
    echo "[$(date)] Checking for monitor layout changes..."
    
    # Load saved position preference (default to top_right)
    POSITION_PREF="top_right"
    if [ -f "$HOME/.config/conky/.monitor_preference" ]; then
        POSITION_PREF=$(cat "$HOME/.config/conky/.monitor_preference")
    fi
    
    # Handle monitor changes (will reload Conky if layout changed)
    if command -v handle_monitor_changes >/dev/null 2>&1; then
        handle_monitor_changes "$HOME/.config/conky/conky.conf" "$INSTALL_DIR" "$POSITION_PREF"
    fi
else
    echo "[$(date)] Configuration file not yet created, will generate at launch"
fi

# Detect active interface: prefer Ethernet, fallback to Wi-Fi
iface=$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/ {print $5; exit}')
[ -z "$iface" ] && iface=$(nmcli device status | awk '$3 == "connected" && $2 == "wifi" {print $1; exit}')
[ -z "$iface" ] && iface=$(nmcli device status | awk '$3 == "connected" {print $1; exit}')
[ -z "$iface" ] && iface="enp7s0"  # final fallback: replace "enp7s0" with your actual network interface name if different
echo "[$(date)] Detected network interface: $iface"

# Save the interface
mkdir -p "$HOME/.config/conky"
echo "$iface" > "$HOME/.config/conky/.conky_iface"

# Replace @@IFACE@@ in conky.conf
if [ ! -f "$HOME/.config/conky/conky.conf" ]; then
    echo "[$(date)] ERROR: Configuration file $HOME/.config/conky/conky.conf not found."
    exit 1
fi
echo "[$(date)] Found conky.conf, proceeding with updates..."

# Update weather location from saved preference (supports auto mode)
if [ -f "$HOME/.config/conky/.conky_location" ]; then
    saved_location=$(tr -d '\n' < "$HOME/.config/conky/.conky_location")
    if [ -n "$saved_location" ] && command -v detect_weather_location >/dev/null 2>&1; then
        if [[ "$saved_location" =~ ^[Aa][Uu][Tt][Oo]$ ]]; then
            resolved_location=$(detect_weather_location)
            echo "🌐 Auto-detected weather location: $resolved_location"
        else
            resolved_location="$saved_location"
        fi
        update_weather_location_in_config "$HOME/.config/conky/conky.conf" "$resolved_location"
        if check_weather_location "$resolved_location"; then
            echo "✅ Weather location check passed"
        else
            echo "⚠️  Weather check failed for '$resolved_location'"
        fi
    fi
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
echo "[$(date)] 🚀 Starting Conky in background..."
if command -v conky >/dev/null 2>&1; then
    conky -c "$HOME/.config/conky/conky.conf" &
    conky_pid=$!
    echo "[$(date)] ✅ Conky started successfully (PID: $conky_pid)"
    echo "[$(date)] 💡 Conky is now running in the background"
else
    echo "[$(date)] ERROR: Conky command not found. Is it installed?"
    exit 1
fi

#!/bin/bash
# Module to monitor and handle display changes dynamically

# Get current monitor configuration snapshot
get_monitor_snapshot() {
    if ! command -v xrandr >/dev/null 2>&1; then
        echo "unknown"
        return
    fi
    
    # Create a hash of current monitor setup
    xrandr --query | grep ' connected' | awk '{print $1, $2}' | sort | md5sum | awk '{print $1}'
}

# Check if monitor layout has changed compared to saved state
monitor_layout_changed() {
    local saved_snapshot_file="$HOME/.config/conky/.monitor_snapshot"
    local current_snapshot
    
    current_snapshot=$(get_monitor_snapshot)
    
    if [ ! -f "$saved_snapshot_file" ]; then
        # First run, save snapshot
        echo "$current_snapshot" > "$saved_snapshot_file"
        return 1  # No change (first time)
    fi
    
    local saved_snapshot
    saved_snapshot=$(cat "$saved_snapshot_file")
    
    if [ "$current_snapshot" != "$saved_snapshot" ]; then
        echo "$current_snapshot" > "$saved_snapshot_file"
        return 0  # Change detected
    fi
    
    return 1  # No change
}

# Recalculate positioning when monitors change
recalculate_monitor_position() {
    local config_file="$1"
    local install_dir="$2"
    local position_pref="${3:-top_right}"
    local saved_monitor_pref_file="$HOME/.config/conky/.monitor_preference"
    
    # Source monitor detection module
    if [ -f "$install_dir/modules/monitor.sh" ]; then
        source "$install_dir/modules/monitor.sh"
    else
        echo "   ⚠️ Monitor module not found" >&2
        return 1
    fi
    
    # Load saved position preference if exists
    if [ -f "$saved_monitor_pref_file" ]; then
        position_pref=$(cat "$saved_monitor_pref_file")
    fi
    
    # Detect current monitors
    detect_monitors
    local monitor_count="${MONITOR_INFO[count]:-0}"
    
    if [ "$monitor_count" -eq 0 ]; then
        echo "   ⚠️ No monitors detected" >&2
        return 1
    fi
    
    # Use primary monitor if available, otherwise first
    local selected_monitor
    if [ -n "${MONITOR_INFO[primary]:-}" ]; then
        selected_monitor="${MONITOR_INFO[primary]}"
    else
        selected_monitor="${MONITOR_NAMES[0]}"
    fi
    
    local monitor_index="${MONITOR_INFO["${selected_monitor}_index"]:-0}"
    
    # Calculate new positioning
    local position_info
    position_info=$(calculate_position "$selected_monitor" "$position_pref")
    
    # Parse position info: alignment:gap_x:gap_y
    local alignment gap_x gap_y
    IFS=':' read -r alignment gap_x gap_y <<< "$position_info"
    
    echo "[$(date)] 📐 Recalculating position for monitor: $selected_monitor (index: $monitor_index)" >&2
    echo "[$(date)]    Position: $alignment, Gap X: $gap_x, Gap Y: $gap_y" >&2
    
    # Update the configuration file
    if [ ! -f "$config_file" ]; then
        echo "   ❌ Configuration file $config_file not found" >&2
        return 1
    fi
    
    # Update placeholders in config
    sed -i "s/alignment = '[^']*'/alignment = '$alignment'/" "$config_file"
    sed -i "s/gap_x = [0-9]*/gap_x = $gap_x/" "$config_file"
    sed -i "s/gap_y = [0-9]*/gap_y = $gap_y/" "$config_file"
    sed -i "s/xinerama_head = [0-9]*/xinerama_head = $monitor_index/" "$config_file"
    
    echo "[$(date)] ✅ Configuration updated" >&2
    return 0
}

# Detect which monitors were added/removed
get_monitor_changes() {
    local saved_state_file="$HOME/.config/conky/.monitor_state"
    local current_state
    
    if ! command -v xrandr >/dev/null 2>&1; then
        return
    fi
    
    # Get current connected monitors
    current_state=$(xrandr --query | grep ' connected' | awk '{print $1}' | sort)
    
    if [ -f "$saved_state_file" ]; then
        local saved_state
        saved_state=$(cat "$saved_state_file")
        
        # Find monitors that were added
        while IFS= read -r monitor; do
            if [ -n "$monitor" ] && ! echo "$saved_state" | grep -q "^$monitor$"; then
                echo "ADDED:$monitor"
            fi
        done <<< "$current_state"
        
        # Find monitors that were removed
        while IFS= read -r monitor; do
            if [ -n "$monitor" ] && ! echo "$current_state" | grep -q "^$monitor$"; then
                echo "REMOVED:$monitor"
            fi
        done <<< "$saved_state"
    fi
    
    # Save current state
    echo "$current_state" > "$saved_state_file"
}

# Reload Conky with updated configuration
reload_conky() {
    echo "[$(date)] 🔄 Reloading Conky..." >&2
    
    # Kill existing Conky processes
    pkill -f "conky -c"
    sleep 1
    
    # Restart Conky with new configuration
    if command -v conky >/dev/null 2>&1; then
        conky -c "$HOME/.config/conky/conky.conf" &
        conky_pid=$!
        echo "[$(date)] ✅ Conky reloaded (PID: $conky_pid)" >&2
        return 0
    else
        echo "[$(date)] ❌ Conky command not found" >&2
        return 1
    fi
}

# Save monitor preference for future use
save_monitor_preference() {
    local position_pref="$1"
    mkdir -p "$HOME/.config/conky"
    echo "$position_pref" > "$HOME/.config/conky/.monitor_preference"
}

# Main function: handle monitor changes
handle_monitor_changes() {
    local config_file="$1"
    local install_dir="$2"
    local position_pref="${3:-top_right}"
    
    # Check if layout changed
    if monitor_layout_changed; then
        echo "[$(date)] 🖥️  Monitor layout changed detected!" >&2
        
        # Log what changed
        get_monitor_changes | while read -r change; do
            echo "[$(date)] $change" >&2
        done
        
        # Recalculate positioning
        if recalculate_monitor_position "$config_file" "$install_dir" "$position_pref"; then
            # Reload Conky with new configuration
            reload_conky
        else
            echo "[$(date)] ⚠️ Failed to recalculate monitor position" >&2
            return 1
        fi
    fi
    
    return 0
}

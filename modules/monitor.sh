#!/bin/bash
# Module to detect monitors and handle multi-monitor positioning

# Global monitor information arrays
declare -A MONITOR_INFO
declare -a MONITOR_NAMES
declare -a MONITOR_RESOLUTIONS
declare -a MONITOR_POSITIONS

# Detect all connected monitors with full details
detect_monitors() {
    MONITOR_NAMES=()
    MONITOR_RESOLUTIONS=()
    MONITOR_POSITIONS=()
    # Clear existing monitor info but keep it global
    for key in "${!MONITOR_INFO[@]}"; do
        unset MONITOR_INFO["$key"]
    done

    if ! command -v xrandr >/dev/null 2>&1; then
        echo "   ⚠️ xrandr not found. Using single monitor fallback."
        MONITOR_NAMES=("unknown")
        MONITOR_RESOLUTIONS=("1920x1080")
        MONITOR_POSITIONS=("0x0")
        MONITOR_INFO["count"]=1
        return
    fi

    local monitor_count=0
    while IFS= read -r line; do
        # Skip disconnected monitors
        if [[ $line =~ disconnected ]]; then
            continue
        fi
        
        # Extract monitor name first
        local name=$(echo "$line" | awk '{print $1}')
        
        # Check if this line contains resolution and position info
        if [[ $line =~ ([0-9]+x[0-9]+)\+([0-9]+)\+([0-9]+) ]]; then
            local resolution="${BASH_REMATCH[1]}"
            local pos_x="${BASH_REMATCH[2]}"
            local pos_y="${BASH_REMATCH[3]}"
            local position="${pos_x}+${pos_y}"
            
            MONITOR_NAMES+=("$name")
            MONITOR_RESOLUTIONS+=("$resolution")
            MONITOR_POSITIONS+=("$position")
            
            MONITOR_INFO["${name}_resolution"]="$resolution"
            MONITOR_INFO["${name}_position"]="$position"
            MONITOR_INFO["${name}_index"]="$monitor_count"
            
            # Extract width and height
            local width=$(echo "$resolution" | cut -d'x' -f1)
            local height=$(echo "$resolution" | cut -d'x' -f2)
            MONITOR_INFO["${name}_width"]="$width"
            MONITOR_INFO["${name}_height"]="$height"
            
            # Store x and y position
            MONITOR_INFO["${name}_x"]="$pos_x"
            MONITOR_INFO["${name}_y"]="$pos_y"
            
            # Determine if this is the primary monitor
            if [[ $line =~ primary ]]; then
                MONITOR_INFO["primary"]="$name"
                MONITOR_INFO["primary_index"]="$monitor_count"
            fi
            
            ((monitor_count++))
        fi
    done < <(xrandr --query | grep ' connected')
    
    MONITOR_INFO["count"]="$monitor_count"
    
    # If no primary monitor detected, set first as primary
    if [[ -z "${MONITOR_INFO[primary]:-}" ]] && [[ $monitor_count -gt 0 ]]; then
        MONITOR_INFO["primary"]="${MONITOR_NAMES[0]}"
        MONITOR_INFO["primary_index"]="0"
    fi
}

# Display monitor information in a formatted way
show_monitor_info() {
    local count="${MONITOR_INFO[count]:-0}"
    echo "   🖥️  Detected $count monitor(s):"
    echo ""
    
    if [[ "$count" -eq 0 ]]; then
        echo "   ⚠️  No monitors detected by xrandr"
        return
    fi
    
    for i in "${!MONITOR_NAMES[@]}"; do
        local name="${MONITOR_NAMES[$i]}"
        local resolution="${MONITOR_INFO["${name}_resolution"]:-unknown}"
        local position="${MONITOR_INFO["${name}_position"]:-0+0}"
        local width="${MONITOR_INFO["${name}_width"]:-0}"
        local height="${MONITOR_INFO["${name}_height"]:-0}"
        local is_primary=""
        
        if [[ "${MONITOR_INFO[primary]:-}" == "$name" ]]; then
            is_primary=" ⭐ Primary"
        fi
        
        echo "   [$((i+1))] $name$is_primary"
        echo "       • Resolution: $resolution (${width}×${height} pixels)"
        echo "       • Position: +$position"
        echo ""
    done
}

# Calculate optimal window positioning based on monitor resolution
calculate_position() {
    local monitor_name="$1"
    local position_preference="${2:-top_right}"  # top_right, top_left, bottom_right, bottom_left, center
    
    local width="${MONITOR_INFO["${monitor_name}_width"]:-1920}"
    local height="${MONITOR_INFO["${monitor_name}_height"]:-1080}"
    local pos_x="${MONITOR_INFO["${monitor_name}_x"]:-0}"
    local pos_y="${MONITOR_INFO["${monitor_name}_y"]:-0}"
    
    # Conky window dimensions (can be made configurable)
    local conky_width=320
    local conky_height=600
    local margin=30
    
    local gap_x gap_y alignment
    
    case "$position_preference" in
        "top_right")
            gap_x=$margin
            gap_y=$margin
            alignment="top_right"
            ;;
        "top_left")
            gap_x=$margin
            gap_y=$margin
            alignment="top_left"
            ;;
        "bottom_right")
            gap_x=$margin
            gap_y=$margin
            alignment="bottom_right"
            ;;
        "bottom_left")
            gap_x=$margin
            gap_y=$margin
            alignment="bottom_left"
            ;;
        "center")
            gap_x=$(( (width - conky_width) / 2 ))
            gap_y=$(( (height - conky_height) / 2 ))
            alignment="top_left"
            ;;
        *)
            # Default to top_right
            gap_x=$margin
            gap_y=$margin
            alignment="top_right"
            ;;
    esac
    
    # For multi-monitor setups, we need to account for monitor offset
    if [[ "${MONITOR_INFO[count]:-0}" -gt 1 ]]; then
        case "$alignment" in
            "top_left"|"bottom_left")
                gap_x=$((pos_x + gap_x))
                ;;
            "top_right"|"bottom_right")
                # For right-aligned, convert to left-based absolute positioning
                gap_x=$((pos_x + width - conky_width - gap_x))
                # Ensure gap_x is not negative
                if [[ $gap_x -lt 0 ]]; then
                    gap_x=$pos_x
                fi
                ;;
        esac
        
        case "$alignment" in
            "bottom_left"|"bottom_right")
                gap_y=$((pos_y + height - conky_height - gap_y))
                # Ensure gap_y is not negative
                if [[ $gap_y -lt 0 ]]; then
                    gap_y=$pos_y
                fi
                ;;
            "top_left"|"top_right"|"center")
                gap_y=$((pos_y + gap_y))
                ;;
        esac
        
        # For multi-monitor setups, use top_left with absolute positioning
        alignment="top_left"
    fi
    
    echo "$alignment:$gap_x:$gap_y"
}

# Enhanced monitor selection with positioning options
get_monitor_config() {
    local noninteractive="$1"
    local position_pref="${2:-top_right}"
    
    # First detect all monitors
    detect_monitors
    
    local count="${MONITOR_INFO[count]}"
    local selected_monitor selected_index
    
    if [[ $count -eq 0 ]]; then
        echo "   ⚠️ No monitors detected. Using fallback configuration." >&2
        echo "0:top_right:30:30"
        return
    elif [[ $count -eq 1 ]]; then
        selected_monitor="${MONITOR_NAMES[0]}"
        selected_index=0
        echo "   ✅ Single monitor detected: $selected_monitor" >&2
    else
        # First, show detailed monitor information
        show_monitor_info >&2
        
        if [[ "$noninteractive" == true ]]; then
            # Use primary monitor if available, otherwise first monitor
            if [[ -n "${MONITOR_INFO[primary]:-}" ]]; then
                selected_monitor="${MONITOR_INFO[primary]}"
                selected_index="${MONITOR_INFO[primary_index]}"
                echo "   🎯 Non-interactive mode: using primary monitor ($selected_monitor)" >&2
            else
                selected_monitor="${MONITOR_NAMES[0]}"
                selected_index=0
                echo "   🎯 Non-interactive mode: using first monitor ($selected_monitor)" >&2
            fi
        else
            # Now ask for user selection with clear prompt
            local default_choice=1
            if [[ -n "${MONITOR_INFO[primary_index]:-}" ]]; then
                default_choice=$((${MONITOR_INFO[primary_index]} + 1))
            fi
            
            echo "   ❓ Select monitor for Conky display [1-$count, default: $default_choice]:" >&2
            echo -n "   Enter monitor number: " >&2
            read choice
            if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [[ "$choice" -le "$count" ]]; then
                selected_index=$((choice-1))
            else
                selected_index=$((default_choice-1))
            fi
            selected_monitor="${MONITOR_NAMES[$selected_index]}"
        fi
    fi
    
    # Calculate positioning
    local position_info
    position_info=$(calculate_position "$selected_monitor" "$position_pref")
    
    echo "${selected_index}:${position_info}"
}

# Legacy function for backward compatibility
get_monitor_index() {
    local noninteractive="$1"
    local config_result
    config_result=$(get_monitor_config "$noninteractive")
    echo "$config_result" | cut -d':' -f1
}

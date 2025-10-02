#!/bin/bash
# Module to detect monitors and select a monitor index

# Detect connected monitors and select MONITOR_INDEX
get_monitor_index() {
    local noninteractive="$1"
    local monitor_list=()
    local monitor_index=0

    if command -v xrandr >/dev/null 2>&1; then
        while IFS= read -r line; do
            name=$(echo "$line" | awk '{print $1}')
            monitor_list+=("$name")
        done < <(xrandr --query | grep ' connected')
        local count=${#monitor_list[@]}
        if [ "$count" -eq 0 ]; then
            monitor_index=0
        elif [ "$count" -eq 1 ]; then
            monitor_index=0
        else
            if [ "$noninteractive" = true ]; then
                monitor_index=0
            else
                echo "Detected $count monitors:" 
                for i in "${!monitor_list[@]}"; do
                    echo "  $((i+1)). ${monitor_list[$i]}"
                done
                read -p "Enter monitor number [1]: " choice
                if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "$count" ]; then
                    monitor_index=$((choice-1))
                else
                    monitor_index=0
                fi
            fi
        fi
    else
        monitor_index=0
    fi
    echo "$monitor_index"
}

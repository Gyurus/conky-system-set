#!/bin/bash
# Simple test for monitor detection

echo "Raw xrandr output:"
xrandr --query | grep ' connected'
echo ""

echo "Testing regex match:"
while IFS= read -r line; do
    echo "Processing line: '$line'"
    
    # Skip disconnected monitors
    if [[ $line =~ disconnected ]]; then
        echo "  -> Skipping disconnected monitor"
        continue
    fi
    
    # Extract monitor name first
    name=$(echo "$line" | awk '{print $1}')
    echo "  -> Monitor name: '$name'"
    
    # Check if this line contains resolution and position info
    if [[ $line =~ ([0-9]+x[0-9]+)\+([0-9]+)\+([0-9]+) ]]; then
        resolution="${BASH_REMATCH[1]}"
        pos_x="${BASH_REMATCH[2]}"
        pos_y="${BASH_REMATCH[3]}"
        echo "  -> Found resolution: $resolution at position $pos_x+$pos_y"
        
        if [[ $line =~ primary ]]; then
            echo "  -> This is the primary monitor"
        fi
    else
        echo "  -> No resolution/position found"
    fi
    echo ""
done < <(xrandr --query | grep ' connected')
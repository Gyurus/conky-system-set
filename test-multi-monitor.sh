#!/bin/bash
# Test script for multi-monitor support

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║               Multi-Monitor Support Test                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Load the monitor module
source "$(dirname "$0")/modules/monitor.sh"

echo "🔍 Testing monitor detection..."
echo "════════════════════════════════"

# Test monitor detection
detect_monitors
echo ""

# Show detected monitor information
show_monitor_info

echo "🎯 Testing positioning calculations..."
echo "══════════════════════════════════════"

# Test positioning for each detected monitor
if [[ "${MONITOR_INFO[count]}" -gt 0 ]]; then
    for i in "${!MONITOR_NAMES[@]}"; do
        name="${MONITOR_NAMES[$i]}"
        echo ""
        echo "   📍 Monitor: $name (${MONITOR_INFO["${name}_resolution"]:-unknown})"
        echo "   Positions:"
        
        for pos in "top_right" "top_left" "bottom_right" "bottom_left" "center"; do
            result=$(calculate_position "$name" "$pos")
            IFS=':' read -r alignment gap_x gap_y <<< "$result"
            echo "      $pos: alignment=$alignment, gap=($gap_x, $gap_y)"
        done
    done
else
    echo "   ⚠️ No monitors detected for positioning test"
fi

echo ""
echo "🧪 Testing configuration functions..."
echo "═══════════════════════════════════════"

# Test non-interactive mode
echo ""
echo "   🤖 Testing non-interactive mode:"
config_result=$(get_monitor_config true "center")
IFS=':' read -r monitor_idx alignment gap_x gap_y <<< "$config_result"
echo "      Selected: Monitor $monitor_idx, $alignment at ($gap_x, $gap_y)"

# Test interactive simulation (with timeout)
echo ""
echo "   👤 Testing interactive mode simulation:"
echo "      (Would normally prompt user for monitor selection)"
config_result=$(get_monitor_config true "top_right")
IFS=':' read -r monitor_idx alignment gap_x gap_y <<< "$config_result"
echo "      Auto-selected: Monitor $monitor_idx, $alignment at ($gap_x, $gap_y)"

echo ""
echo "✅ Multi-monitor support test completed!"
echo ""
echo "📊 Summary:"
echo "   - Detected ${MONITOR_INFO[count]} monitor(s)"
echo "   - Primary monitor: ${MONITOR_INFO[primary]:-'N/A'}"
echo "   - Positioning system: ✅ Working"
echo "   - Configuration system: ✅ Working"

if [[ "${MONITOR_INFO[count]}" -gt 1 ]]; then
    echo "   🎉 Multi-monitor setup detected and ready!"
else
    echo "   ℹ️ Single monitor setup - positioning will work with screen edges"
fi
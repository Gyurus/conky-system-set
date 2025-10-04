#!/bin/bash
# Test interactive monitor selection

echo "🧪 Testing Interactive Monitor Selection"
echo "========================================"

cd /home/gyuri/Work/Conky/conky-system-set
source modules/monitor.sh

echo ""
echo "📋 Testing interactive mode simulation:"
echo "   This will test the interactive monitor selection without actually prompting"
echo ""

# Simulate interactive mode with timeout
echo "1" | timeout 5s bash -c '
    source modules/monitor.sh
    config_result=$(get_monitor_config false "top_right")
    echo "Selected config: $config_result"
'

echo ""
echo "✅ Interactive test completed!"
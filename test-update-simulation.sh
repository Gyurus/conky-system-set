#!/bin/bash
# Test script to simulate update available scenario

echo "🧪 SIMULATING UPDATE AVAILABLE SCENARIO"
echo "======================================="
echo ""

cd /home/gyuri/Work/Conky/conky-system-set
source modules/update.sh

# Override the get_latest_version function to simulate a newer version
get_latest_version() {
    echo "v1.8.0"  # Simulate a newer version than current 1.7-dev
}

# Override the current version to be older
CURRENT_VERSION="1.6.0"

echo "📋 Simulated Scenario:"
echo "   Current version: $(get_current_version)"
echo "   Latest version: $(get_latest_version)"
echo ""

echo "🔍 Running update check..."
check_for_updates "true" "true"  # Force check, non-interactive

echo ""
echo "🎯 Test completed!"
echo ""

echo "📋 To test interactive mode, create a simple test:"
echo "   cd /home/gyuri/Work/Conky/conky-system-set"
echo "   source modules/update.sh"
echo "   show_update_prompt \"v1.8.0\""
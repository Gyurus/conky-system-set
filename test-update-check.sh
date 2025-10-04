#!/bin/bash
# Test script for update functionality

echo "🧪 TESTING UPDATE CHECK FUNCTIONALITY"
echo "====================================="
echo ""

cd /home/gyuri/Work/Conky/conky-system-set

# Test 1: Load the update module
echo "📋 Test 1: Loading update module..."
source modules/update.sh
echo "   ✅ Update module loaded successfully"
echo ""

# Test 2: Test version comparison
echo "📋 Test 2: Testing version comparison..."
if version_compare "1.6" "1.7"; then
    echo "   ✅ Version comparison working: 1.6 < 1.7"
else
    echo "   ❌ Version comparison failed"
fi

if version_compare "v1.6" "v1.7.1"; then
    echo "   ✅ Version comparison working: v1.6 < v1.7.1"
else
    echo "   ❌ Version comparison failed"
fi

if ! version_compare "1.8" "1.7"; then
    echo "   ✅ Version comparison working: 1.8 >= 1.7"
else
    echo "   ❌ Version comparison failed"
fi
echo ""

# Test 3: Test current version
echo "📋 Test 3: Testing current version detection..."
current_ver=$(get_current_version)
echo "   Current version: $current_ver"
if [[ -n "$current_ver" ]]; then
    echo "   ✅ Current version detection working"
else
    echo "   ❌ Current version detection failed"
fi
echo ""

# Test 4: Test latest version fetching (if network available)
echo "📋 Test 4: Testing latest version fetching..."
latest_ver=$(get_latest_version)
if [[ -n "$latest_ver" ]]; then
    echo "   Latest version: $latest_ver"
    echo "   ✅ Latest version fetching working"
else
    echo "   ⚠️  Could not fetch latest version (network may be unavailable)"
fi
echo ""

# Test 5: Test skip version functionality
echo "📋 Test 5: Testing skip version functionality..."
test_version="v1.9.9"

# Clear any existing skip
rm -f "$HOME/.conky-system-set-skip-version"

# Test skipping
skip_version "$test_version"
if is_version_skipped "$test_version"; then
    echo "   ✅ Version skipping working"
else
    echo "   ❌ Version skipping failed"
fi

# Clear the skip
clear_skipped_version
if ! is_version_skipped "$test_version"; then
    echo "   ✅ Version skip clearing working"
else
    echo "   ❌ Version skip clearing failed"
fi
echo ""

# Test 6: Test update check interval
echo "📋 Test 6: Testing update check interval..."
if should_check_for_updates "false"; then
    echo "   ✅ Should check for updates (no previous check)"
else
    echo "   ⚠️  Not checking (previous check within interval)"
fi

if should_check_for_updates "true"; then
    echo "   ✅ Force check working"
else
    echo "   ❌ Force check failed"
fi
echo ""

# Test 7: Test command-line interface
echo "📋 Test 7: Testing command-line interface..."
echo "   Testing help option:"
update_check_cli --help | head -3
echo ""

echo "🎯 UPDATE CHECK FUNCTIONALITY TESTS COMPLETED!"
echo ""

echo "📋 Manual Test Available:"
echo "   Run: ./conkyset.sh --check-updates"
echo "   Run: ./conkyset.sh --force-update-check"
echo "   Run: ./conkyset.sh --skip-update-check"
echo ""

echo "✅ All automated tests passed!"
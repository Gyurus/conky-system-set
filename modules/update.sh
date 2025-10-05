#!/bin/bash
# Module for update checking and version management

# Version information
CURRENT_VERSION="1.8.4"
VERSION_CHECK_URL="https://api.github.com/repos/Gyurus/conky-system-set/releases/latest"
SKIP_VERSION_FILE="$HOME/.conky-system-set-skip-version"
UPDATE_CHECK_FILE="$HOME/.conky-system-set-last-check"
UPDATE_CHECK_INTERVAL=86400  # 24 hours in seconds

# Get the current version
get_current_version() {
    echo "$CURRENT_VERSION"
}

# Get the latest version from GitHub
get_latest_version() {
    local latest_version
    
    # Try to fetch latest version from GitHub API
    if command -v curl >/dev/null 2>&1; then
        latest_version=$(curl -s --max-time 10 "$VERSION_CHECK_URL" 2>/dev/null | \
            grep '"tag_name":' | \
            sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/' | \
            head -1)
    elif command -v wget >/dev/null 2>&1; then
        latest_version=$(wget -qO- --timeout=10 "$VERSION_CHECK_URL" 2>/dev/null | \
            grep '"tag_name":' | \
            sed -E 's/.*"tag_name":\s*"([^"]+)".*/\1/' | \
            head -1)
    else
        echo ""
        return 1
    fi
    
    # Validate the version format (should start with 'v' followed by numbers and dots)
    if [[ "$latest_version" =~ ^v[0-9]+\.[0-9]+.*$ ]]; then
        echo "$latest_version"
        return 0
    else
        echo ""
        return 1
    fi
}

# Compare version strings (returns 0 if v1 < v2, 1 if v1 >= v2)
version_compare() {
    local v1="$1"
    local v2="$2"
    
    # Remove 'v' prefix and any suffixes like '-dev'
    v1=$(echo "$v1" | sed 's/^v//' | sed 's/-.*$//')
    v2=$(echo "$v2" | sed 's/^v//' | sed 's/-.*$//')
    
    # Split versions into arrays
    IFS='.' read -ra v1_parts <<< "$v1"
    IFS='.' read -ra v2_parts <<< "$v2"
    
    # Pad arrays to same length
    local max_length=$((${#v1_parts[@]} > ${#v2_parts[@]} ? ${#v1_parts[@]} : ${#v2_parts[@]}))
    
    for ((i=0; i<max_length; i++)); do
        local part1=${v1_parts[i]:-0}
        local part2=${v2_parts[i]:-0}
        
        if [[ $part1 -lt $part2 ]]; then
            return 0  # v1 < v2
        elif [[ $part1 -gt $part2 ]]; then
            return 1  # v1 > v2
        fi
    done
    
    return 1  # v1 == v2
}

# Check if version should be skipped
is_version_skipped() {
    local version="$1"
    
    if [[ -f "$SKIP_VERSION_FILE" ]]; then
        local skipped_version
        skipped_version=$(cat "$SKIP_VERSION_FILE" 2>/dev/null)
        [[ "$skipped_version" == "$version" ]]
    else
        return 1
    fi
}

# Mark version as skipped
skip_version() {
    local version="$1"
    echo "$version" > "$SKIP_VERSION_FILE"
    echo "   ℹ️  Version $version marked as skipped."
}

# Clear skipped version
clear_skipped_version() {
    rm -f "$SKIP_VERSION_FILE"
    echo "   ✅ Cleared skipped version preference."
}

# Check if we should perform an update check (respects interval)
should_check_for_updates() {
    local force_check="$1"
    
    # Always check if forced
    if [[ "$force_check" == "true" ]]; then
        return 0
    fi
    
    # Check if we've checked recently
    if [[ -f "$UPDATE_CHECK_FILE" ]]; then
        local last_check
        last_check=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null)
        local current_time
        current_time=$(date +%s)
        
        if [[ -n "$last_check" ]] && [[ $((current_time - last_check)) -lt $UPDATE_CHECK_INTERVAL ]]; then
            return 1  # Don't check yet
        fi
    fi
    
    return 0  # Should check
}

# Update the last check timestamp
update_check_timestamp() {
    date +%s > "$UPDATE_CHECK_FILE"
}

# Main update check function
check_for_updates() {
    local force_check="$1"
    local noninteractive="$2"
    
    # Check if we should perform the check
    if ! should_check_for_updates "$force_check"; then
        return 0
    fi
    
    echo "   🔍 Checking for updates..."
    
    # Get latest version
    local latest_version
    latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        echo "   ⚠️  Unable to check for updates (network issue or API unavailable)"
        return 1
    fi
    
    # Update check timestamp
    update_check_timestamp
    
    local current_version
    current_version=$(get_current_version)
    
    echo "   📋 Current version: $current_version"
    echo "   📋 Latest version: $latest_version"
    
    # Compare versions
    if version_compare "$current_version" "$latest_version"; then
        # New version available
        echo ""
        echo "   🎉 New version available: $latest_version"
        
        # Check if this version is skipped
        if is_version_skipped "$latest_version"; then
            echo "   ⏭️  Version $latest_version is marked as skipped."
            return 0
        fi
        
        # Show update prompt if not in non-interactive mode
        if [[ "$noninteractive" != "true" ]]; then
            show_update_prompt "$latest_version"
        else
            echo "   ℹ️  Run with --check-updates to see update options."
        fi
    else
        echo "   ✅ You have the latest version!"
    fi
}

# Show update prompt to user
show_update_prompt() {
    local latest_version="$1"
    
    echo ""
    echo "   🔄 Update Options:"
    echo "   =================="
    echo ""
    echo "   1. Update now (recommended)"
    echo "   2. Skip this version"
    echo "   3. Remind me later"
    echo "   4. Show release notes"
    echo ""
    
    while true; do
        echo -n "   ❓ What would you like to do? [1]: " >&2
        read choice
        
        case "${choice:-1}" in
            1)
                perform_update "$latest_version"
                break
                ;;
            2)
                skip_version "$latest_version"
                break
                ;;
            3)
                echo "   ⏰ You'll be reminded about this update later."
                break
                ;;
            4)
                show_release_notes "$latest_version"
                # Continue the loop to show options again
                ;;
            *)
                echo "   ❌ Invalid choice. Please enter 1, 2, 3, or 4."
                ;;
        esac
    done
}

# Show release notes for a version
show_release_notes() {
    local version="$1"
    
    echo ""
    echo "   📄 Release Notes for $version:"
    echo "   =============================="
    
    if command -v curl >/dev/null 2>&1; then
        local release_notes
        release_notes=$(curl -s --max-time 10 "$VERSION_CHECK_URL" 2>/dev/null | \
            grep '"body":' | \
            sed 's/.*"body":\s*"//' | \
            sed 's/",.*$//' | \
            sed 's/\\n/\n/g' | \
            sed 's/\\"/"/g' | \
            head -20)
        
        if [[ -n "$release_notes" ]]; then
            echo "$release_notes" | head -20
        else
            echo "   ⚠️  Unable to fetch release notes."
        fi
    else
        echo "   ⚠️  curl not available to fetch release notes."
    fi
    
    echo ""
    echo "   🌐 Full details: https://github.com/Gyurus/conky-system-set/releases/tag/$version"
    echo ""
}

# Perform the actual update
perform_update() {
    local latest_version="$1"
    
    echo ""
    echo "   🚀 Starting update to $latest_version..."
    echo ""
    
    # Check if we're in a git repository
    if [[ -d ".git" ]]; then
        echo "   📂 Detected git repository. Updating via git..."
        
        # Stash any local changes
        if ! git diff --quiet || ! git diff --cached --quiet; then
            echo "   💾 Stashing local changes..."
            git stash push -m "Auto-stash before update to $latest_version"
        fi
        
        # Fetch latest changes
        echo "   📥 Fetching latest changes..."
        if git fetch origin; then
            # Checkout the latest version tag
            echo "   🔄 Switching to version $latest_version..."
            if git checkout "$latest_version"; then
                echo "   ✅ Successfully updated to $latest_version!"
                echo ""
                echo "   🎯 Update completed! You may need to run the setup again if there were configuration changes."
                echo "   Run: ./conkyset.sh --help to see any new options"
            else
                echo "   ❌ Failed to checkout version $latest_version"
                return 1
            fi
        else
            echo "   ❌ Failed to fetch updates from repository"
            return 1
        fi
    else
        echo "   📦 Git repository not detected. Manual update required."
        echo ""
        echo "   📋 Manual Update Instructions:"
        echo "   =============================="
        echo "   1. Download the latest release:"
        echo "      https://github.com/Gyurus/conky-system-set/releases/tag/$latest_version"
        echo "   2. Extract the archive"
        echo "   3. Replace your current files with the new ones"
        echo "   4. Run ./conkyset.sh to reconfigure"
        echo ""
    fi
}

# Command-line interface for update checking
update_check_cli() {
    local force="false"
    local noninteractive="false"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force="true"
                shift
                ;;
            --noninteractive)
                noninteractive="true"
                shift
                ;;
            --clear-skip)
                clear_skipped_version
                shift
                ;;
            --help)
                echo "Update Check Usage:"
                echo "  --force           Force update check regardless of interval"
                echo "  --noninteractive  Don't prompt for user input"
                echo "  --clear-skip      Clear skipped version preference"
                echo "  --help            Show this help"
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    check_for_updates "$force" "$noninteractive"
}
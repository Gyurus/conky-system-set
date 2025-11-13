#!/bin/bash
# Version update script for Conky System Set
# Usage: ./update_version.sh <new_version>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new_version>"
    echo "Example: $0 1.8.9"
    exit 1
fi

NEW_VERSION="$1"

# Validate version format (should be x.y.z)
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "Error: Version must be in format x.y.z (e.g., 1.8.7)"
    exit 1
fi

echo "Updating version to $NEW_VERSION..."

# Update VERSION file
echo "$NEW_VERSION" > VERSION

# Update README.md title
sed -i "s/# Conky System Set v[0-9]\+\.[0-9]\+\.[0-9]\+/# Conky System Set v$NEW_VERSION/" README.md

echo "✅ Version updated to $NEW_VERSION"
echo "📝 Remember to update the 'What's New' section in README.md for this version"
#!/bin/bash
# Quick fix for module path issues after copying scripts

echo "🔧 Fixing module path issues..."
echo ""

# Check if installation directory exists
if [ ! -d "$HOME/.conky-system-set" ]; then
    echo "❌ Installation directory not found: $HOME/.conky-system-set"
    echo "Please reinstall using the online installer."
    exit 1
fi

# Remove copied scripts
echo "Removing copied scripts..."
rm -f ~/conkyset.sh ~/conkystartup.sh ~/rm-conkyset.sh

# Create proper symlinks
echo "Creating symlinks..."
ln -sf ~/.conky-system-set/conkyset.sh ~/conkyset.sh
ln -sf ~/.conky-system-set/conkystartup.sh ~/conkystartup.sh
ln -sf ~/.conky-system-set/rm-conkyset.sh ~/rm-conkyset.sh

echo ""
echo "✅ Fixed! Symlinks created:"
ls -l ~/conkyset.sh ~/conkystartup.sh ~/rm-conkyset.sh | grep '\->'
echo ""
echo "You can now run: ~/conkyset.sh"

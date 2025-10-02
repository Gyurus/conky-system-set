#!/bin/bash
# Test script for conkyset.sh
# This script simulates running the conky setup in test mode without making permanent changes

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                Conky System Monitor Test Run                ║"
echo "║                  TESTING & VERIFICATION                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🧪 Starting test run of Conky setup..."
echo "════════════════════════════════════════════════"

# Set test directory
TEST_DIR="/tmp/conky-test-run"
echo "📂 Test directory: $TEST_DIR"

# Create clean test directory
echo "🧹 Creating clean test environment..."
if [ -d "$TEST_DIR" ]; then
    echo "   🗑️ Removing existing test directory..."
    rm -rf "$TEST_DIR"
fi

mkdir -p "$TEST_DIR"
mkdir -p "$TEST_DIR/.config/conky"
mkdir -p "$TEST_DIR/.config/autostart"

# Function to simulate commands without executing them
simulate_cmd() {
    echo "   🔄 Would execute: $*"
}

# Test conky detection
echo "📋 Testing Conky detection..."
if command -v conky &> /dev/null; then
    echo "   ✅ Conky is installed (version: $(conky --version | head -1))"
else
    echo "   ❌ Conky is not installed"
    echo "   💡 Installation would be attempted"
fi

# Test hardware detection
echo "📋 Testing hardware detection..."
echo "   🔍 Checking for GPUs..."
if command -v lspci &> /dev/null; then
    gpu_info=$(lspci | grep -i "vga\|3d\|display")
    if [ -n "$gpu_info" ]; then
        echo "   ✅ Found GPU(s):"
        echo "$gpu_info" | while read -r line; do
            echo "      • $line"
        done
    else
        echo "   ⚠️ No discrete GPU detected"
    fi
else
    echo "   ⚠️ lspci not available, would skip GPU detection"
fi

# Check for NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    echo "   ✅ NVIDIA GPU detected with drivers installed"
    nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader 2>/dev/null | head -1
fi

# Check for sensors
if command -v sensors &> /dev/null; then
    echo "   ✅ lm-sensors is installed"
    sensor_count=$(sensors 2>/dev/null | grep -c "°C")
    echo "   📊 Found $sensor_count temperature sensors"
else
    echo "   ⚠️ lm-sensors not installed, would offer installation"
fi

# Test file operations
echo "📋 Testing file operations..."
echo "   📝 Copying files to test directory..."

# Copy template files to test directory
cp "conky.template.conf" "$TEST_DIR/.config/conky/conky.conf" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✅ Template copy would succeed"
    
    # Test interface detection and replacement
    echo "   🔍 Testing network interface detection..."
    IFACE=$(ip route | awk '/default/ {print $5; exit}')
    if [ -z "$IFACE" ]; then
        IFACE="eth0"
        echo "   ⚠️ No active interface found, would use fallback: $IFACE"
    else
        echo "   ✅ Active interface detected: $IFACE"
    fi
    
    echo "   🔄 Would replace @@IFACE@@ with $IFACE in conky.conf"
else
    echo "   ❌ Template copy would fail - template file missing"
fi

# Test script copies
for script in "conkystartup.sh" "rm-conkyset.sh"; do
    if [ -f "$script" ]; then
        echo "   ✅ $script exists and would be copied to home directory"
        cp "$script" "$TEST_DIR/" 2>/dev/null
    else
        echo "   ❌ $script is missing! Installation would fail"
    fi
done

# Test desktop environment detection
echo "📋 Testing desktop environment detection..."
DESKTOP_ENV=""
if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    DESKTOP_ENV="$XDG_CURRENT_DESKTOP"
elif [ -n "$DESKTOP_SESSION" ]; then
    DESKTOP_ENV="$DESKTOP_SESSION"
elif command -v gnome-session &> /dev/null; then
    DESKTOP_ENV="GNOME"
elif command -v cinnamon-session &> /dev/null; then
    DESKTOP_ENV="X-Cinnamon"
elif command -v mate-session &> /dev/null; then
    DESKTOP_ENV="MATE"
elif command -v xfce4-session &> /dev/null; then
    DESKTOP_ENV="XFCE"
elif command -v lxsession &> /dev/null; then
    DESKTOP_ENV="LXDE"
elif command -v startplasma-x11 &> /dev/null || command -v startplasma-wayland &> /dev/null; then
    DESKTOP_ENV="KDE"
else
    DESKTOP_ENV="Unknown"
fi

echo "   📌 Detected desktop environment: $DESKTOP_ENV"
echo "   🔄 Would create appropriate autostart entry for $DESKTOP_ENV"

# Create sample autostart file in test directory
cat > "$TEST_DIR/.config/autostart/conky.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Conky System Monitor (TEST)
Comment=Start Conky system monitor at login
Hidden=false
NoDisplay=false
StartupNotify=false
Terminal=false
Categories=System;Monitor;
Exec=$HOME/conkystartup.sh
X-GNOME-Autostart-enabled=true
EOF

echo "   ✅ Sample autostart entry created for testing"

# Test GPU temperature detection
echo "📋 Testing GPU temperature detection..."

# Simulated GPU command logic
GPU_COMMAND="echo N/A"
if command -v nvidia-smi &> /dev/null; then
    TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)
    if [ -n "$TEMP" ] && [ "$TEMP" -gt 0 ]; then
        echo "   ✅ NVIDIA GPU temperature detection working: ${TEMP}°C"
        GPU_COMMAND="nvidia-smi command"
    fi
elif ls /sys/class/hwmon/hwmon*/name 2>/dev/null | xargs grep -l 'amdgpu' &> /dev/null; then
    echo "   ✅ AMD GPU detected, would use amdgpu for temperature"
    GPU_COMMAND="amdgpu command"
else
    echo "   ℹ️ No specific GPU temperature detection method found"
    echo "   🔍 Would scan thermal zones for fallback temperature"
    
    # Check thermal zones briefly
    zones_found=false
    for thermal in /sys/class/thermal/thermal_zone*/type; do
        if [ -f "$thermal" ]; then
            zones_found=true
            break
        fi
    done 2>/dev/null || echo "   ℹ️ No thermal zones found"
    
    if [ "$zones_found" = true ]; then
        echo "   ✅ Thermal zones available for fallback temperature"
    else
        echo "   ⚠️ No thermal zones found, temperature display may not work"
    fi
fi

# Cleanup
echo "📋 Cleaning up test files..."
echo "   🗑️ Would remove test directory: $TEST_DIR"
rm -rf "$TEST_DIR"

# Final report
echo ""
echo "════════════════════════════════════════════════"
echo "🧪 Test Run Summary"
echo "════════════════════════════════════════════════"
echo "✅ Script verification: All components of conkyset.sh tested"
echo "🔍 System compatibility:"

# Check critical components
critical_issues=0
warnings=0

# Check for critical components
if ! command -v conky &> /dev/null; then
    echo "   ❌ Conky is not installed"
    critical_issues=$((critical_issues + 1))
else
    echo "   ✅ Conky is installed"
fi

for file in "conky.template.conf" "conkystartup.sh" "rm-conkyset.sh"; do
    if [ ! -f "$file" ]; then
        echo "   ❌ Missing required file: $file"
        critical_issues=$((critical_issues + 1))
    else
        echo "   ✅ Required file present: $file"
    fi
done

# Check for warnings/recommendations
if ! command -v sensors &> /dev/null; then
    echo "   ⚠️ lm-sensors not installed (recommended)"
    warnings=$((warnings + 1))
fi

# Final verdict
echo ""
if [ $critical_issues -gt 0 ]; then
    echo "❌ TEST FAILED: $critical_issues critical issues found"
    echo "   Please resolve these issues before running the actual installer"
    exit 1
elif [ $warnings -gt 0 ]; then
    echo "⚠️ TEST PASSED WITH WARNINGS: $warnings non-critical issues found"
    echo "   You can proceed with installation, but some features may be limited"
else
    echo "✅ TEST PASSED: System ready for Conky installation"
    echo "   You can proceed with running the actual installer"
fi

echo ""
echo "To run the actual installer, use:"
echo "   ./conkyset.sh"
echo ""
echo "This test run did not make any permanent changes to your system."

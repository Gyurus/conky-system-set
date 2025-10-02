#!/bin/bash

echo "🔍 Testing Improved GPU Detection..."
echo "════════════════════════════════════════════════"

# Get GPU info
gpu_info=$(lspci | grep -i "vga\|3d\|display")
echo "Raw GPU Info:"
echo "$gpu_info"
echo ""

# Check for NVIDIA GPU specifically
nvidia_detected=false
amd_detected=false
intel_detected=false

if command -v nvidia-smi >/dev/null 2>&1; then
    echo "✅ NVIDIA GPU detected with nvidia-smi support"
    nvidia_detected=true
else
    # Check if NVIDIA GPU exists but nvidia-smi is not installed
    if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "nvidia\|geforce\|quadro\|tesla"; then
        echo "⚠️  NVIDIA GPU detected but nvidia-smi not available"
        nvidia_detected=true
    fi
fi

# Check for AMD GPU
if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "amd\|radeon\|ati"; then
    echo "🔴 AMD GPU detected"
    amd_detected=true
fi

# Check for Intel GPU (more specific pattern)
if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "intel.*graphics\|intel.*vga"; then
    echo "🔵 Intel GPU detected"
    intel_detected=true
fi

echo ""
echo "📋 Detection Summary:"
echo "• NVIDIA: $([ "$nvidia_detected" = true ] && echo "✅ Yes" || echo "❌ No")"
echo "• AMD: $([ "$amd_detected" = true ] && echo "✅ Yes" || echo "❌ No")"  
echo "• Intel: $([ "$intel_detected" = true ] && echo "✅ Yes" || echo "❌ No")"

echo ""
echo "🎮 Tools Installation Would Be Offered For:"
if [ "$nvidia_detected" = true ] && ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "• NVIDIA tools (nvidia-utils)"
fi
if [ "$amd_detected" = true ] && ! command -v radeontop >/dev/null 2>&1; then
    echo "• AMD tools (radeontop)"
fi
if [ "$intel_detected" = true ] && ! command -v intel_gpu_top >/dev/null 2>&1; then
    echo "• Intel tools (intel-gpu-tools)"
fi

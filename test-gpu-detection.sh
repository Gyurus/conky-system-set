#!/bin/bash

echo "🔍 Testing GPU Detection and Installation Prompts..."
echo "════════════════════════════════════════════════"

# Check for video card/GPU
echo "🎮 Video Card Detection:"
gpu_info=$(lspci | grep -i "vga\|3d\|display")
if [ -n "$gpu_info" ]; then
    echo "   Found GPU(s):"
    echo "$gpu_info" | while read -r line; do
        echo "   • $line"
    done
else
    echo "   ⚠️  No discrete GPU detected"
fi

# Check for NVIDIA GPU specifically
nvidia_detected=false
amd_detected=false
intel_detected=false

if command -v nvidia-smi >/dev/null 2>&1; then
    echo "   ✅ NVIDIA GPU detected with nvidia-smi support"
    nvidia_detected=true
else
    # Check if NVIDIA GPU exists but nvidia-smi is not installed
    if echo "$gpu_info" | grep -qi "nvidia\|geforce\|quadro\|tesla"; then
        echo "   ⚠️  NVIDIA GPU detected but nvidia-smi not available"
        nvidia_detected=true
    else
        echo "   ℹ️  No NVIDIA GPU detected"
    fi
fi

# Check for AMD GPU
if echo "$gpu_info" | grep -qi "amd\|radeon\|ati"; then
    echo "   🔴 AMD GPU detected"
    amd_detected=true
fi

# Check for Intel GPU
if echo "$gpu_info" | grep -qi "intel"; then
    echo "   🔵 Intel GPU detected"
    intel_detected=true
fi

echo ""
echo "🎮 GPU Monitoring Tools Installation"
echo "════════════════════════════════════════════════"

# NVIDIA GPU tools
if [ "$nvidia_detected" = true ] && ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "🟢 NVIDIA GPU detected without monitoring tools"
    echo "   Recommended: nvidia-utils package for temperature monitoring"
    echo "   This would enable GPU temperature display in Conky"
    echo "   Command would be: sudo apt install nvidia-utils"
    echo ""
fi

# AMD GPU tools  
if [ "$amd_detected" = true ]; then
    echo "🔴 AMD GPU detected"
    if ! command -v radeontop >/dev/null 2>&1; then
        echo "   Recommended: radeontop package for GPU monitoring"
        echo "   Command would be: sudo apt install radeontop"
    else
        echo "   ✅ radeontop already available"
    fi
    echo ""
fi

# Intel GPU tools
if [ "$intel_detected" = true ]; then
    echo "🔵 Intel GPU detected"
    if ! command -v intel_gpu_top >/dev/null 2>&1; then
        echo "   Optional: intel-gpu-tools package for detailed monitoring"
        echo "   Command would be: sudo apt install intel-gpu-tools"
    else
        echo "   ✅ intel-gpu-tools already available"
    fi
    echo ""
fi

echo "✅ GPU detection test completed!"

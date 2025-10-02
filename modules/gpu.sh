#!/bin/bash
# Module for GPU detection and summary

detect_gpus() {
    echo "🔍 Detecting hardware and thermal sensors..."
    echo "════════════════════════════════════════════════"

    # Video Card Detection
    echo "🎮 Video Card Detection:"
    if command -v lspci >/dev/null 2>&1; then
        gpu_info=$(lspci | grep -i "vga\|3d\|display")
        if [ -n "$gpu_info" ]; then
            echo "   Found GPU(s):"
            echo "$gpu_info" | while read -r line; do
                echo "   • $line"
            done
        else
            echo "   ⚠️  No discrete GPU detected"
        fi
    else
        echo "   ⚠️  lspci not available, cannot detect GPU"
    fi

    # NVIDIA GPU Detection
    nvidia_detected=false
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "   ✅ NVIDIA GPU detected with nvidia-smi support"
        nvidia_temp=$(nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
        [ -n "$nvidia_temp" ] && echo "   📊 NVIDIA GPU: $nvidia_temp"
        nvidia_detected=true
    else
        if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "nvidia\|geforce\|quadro\|tesla"; then
            echo "   ⚠️  NVIDIA GPU detected but nvidia-smi not available"
            nvidia_detected=true
        fi
    fi

    # AMD GPU Detection
    amd_detected=false
    if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "\bamd\b\|\bradeon\b\|\bati\b"; then
        echo "   🔴 AMD GPU detected"
        amd_detected=true
        if command -v radeontop >/dev/null 2>&1; then
            echo "   ✅ radeontop available for AMD monitoring"
        else
            echo "   ⚠️  radeontop not installed for AMD monitoring"
        fi
    fi

    # Intel GPU Detection
    intel_detected=false
    if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "intel.*(graphics|vga|controller)"; then
        echo "   🔵 Intel GPU detected"
        intel_detected=true
        if command -v intel_gpu_top >/dev/null 2>&1; then
            echo "   ✅ intel_gpu_top available for Intel monitoring"
        else
            echo "   ℹ️  intel_gpu_top not installed for Intel monitoring"
        fi
    fi

    # Print summary
    echo ""
    echo "   📋 Detection Summary:"
    echo "   • NVIDIA: $([ "$nvidia_detected" = true ] && echo "✅ Yes" || echo "❌ No")"
    echo "   • AMD: $([ "$amd_detected" = true ] && echo "✅ Yes" || echo "❌ No")"
    echo "   • Intel: $([ "$intel_detected" = true ] && echo "✅ Yes" || echo "❌ No")"
}

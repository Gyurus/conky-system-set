#!/bin/bash
# Usage/help function
show_help() {
    echo "Usage: $(basename "$0") [options]"
    echo "Options:"
    echo "  -y, --yes        Non-interactive mode (auto-confirm prompts)"
    echo "      --no-gpu     Skip GPU detection and installation steps"
    echo "      --auto-location  Auto-detect weather location (skip prompt)"
    echo "      --nosensor   Skip thermal sensor checks and installs"
    echo "      --help       Show this help message and exit"
    exit 0
}

# Default flags
NONINTERACTIVE=false
SKIP_GPU=false
AUTO_LOCATION=false
SKIP_SENSOR=false

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)
            NONINTERACTIVE=true
            echo "   ℹ️  Non-interactive mode: auto defaults enabled."
            shift
            ;;
        --no-gpu)
            SKIP_GPU=true
            echo "   ℹ️  GPU detection skipped."
            shift
            ;;
        --help)
            show_help
            ;;
        --auto-location)
            AUTO_LOCATION=true
            echo "   ℹ️  Auto-location enabled (skip manual weather prompt)."
            shift
            ;;
        --nosensor)
            SKIP_SENSOR=true
            echo "   ℹ️  Sensor checks skipped."
            shift
            ;;
        *)
            break
            ;;
    esac
done
# linux
# Start prechecks
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Conky System Monitor                      ║"
echo "║                       SETUP TOOL                             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🚀 Starting Conky setup and installation..."
echo "════════════════════════════════════════════════"

# Load modules
source "$(dirname "$0")/modules/process.sh"
source "$(dirname "$0")/modules/monitor.sh"
source "$(dirname "$0")/modules/iface.sh"
source "$(dirname "$0")/modules/weather.sh"
source "$(dirname "$0")/modules/gpu.sh"

# Kill any existing Conky processes
kill_conky

# Create a single backup timestamp for this run
BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Check for previous config files
if [ -d "$HOME/.config/conky" ]; then
    echo "   📁 Found existing Conky configuration directory."
    if [ "$NONINTERACTIVE" = true ]; then
        clean_config="y"
        echo "   ✅ Non-interactive mode: automatically selected 'yes' to backup and remove existing configuration."
    else
        read -p "   ❓ Do you want to backup and remove the existing configuration? (y/n): " clean_config
    fi
    if [[ "$clean_config" =~ ^[Yy]$ ]]; then
        # Create backup of each file with the format filename.extension.date.time.backup
        if [ -d "$HOME/.config/conky" ] && [ "$(ls -A "$HOME/.config/conky" 2>/dev/null)" ]; then
            echo "   📂 Creating backups of configuration files..."
            # Create backups in the parent directory to avoid deletion
            for file in "$HOME/.config/conky/"*; do
                if [ -f "$file" ]; then
                    filename=$(basename "$file")
                    backup_path="$HOME/.config/${filename}.${BACKUP_TIMESTAMP}.backup"
                    cp "$file" "$backup_path" 2>/dev/null
                    echo "   💾 Backed up: ${filename} → ${filename}.${BACKUP_TIMESTAMP}.backup (in ~/.config/)"
                fi
            done
            echo "   ✅ All configuration files backed up with .${BACKUP_TIMESTAMP}.backup extension"
        fi
        rm -rf "$HOME/.config/conky"
        echo "   🗑️ Removed old Conky configuration directory."
    else
        echo "   ⚠️ Will attempt to use/overwrite existing configuration."
    fi
fi

# Check for previous autostart entries
if [ -f "$HOME/.config/autostart/conky.desktop" ]; then
    echo "   🔄 Found existing Conky autostart entry."
    cp "$HOME/.config/autostart/conky.desktop" "$HOME/.config/autostart/conky.desktop.${BACKUP_TIMESTAMP}.backup" 2>/dev/null
    echo "   💾 Existing autostart entry backed up to: conky.desktop.${BACKUP_TIMESTAMP}.backup"
    echo "   ℹ️ The existing entry will be replaced."
fi

# Check for other Conky-related files in home directory
for file in "$HOME/conkystartup.sh" "$HOME/rm-conkyset.sh" "$HOME/.conkyrc"; do
    if [ -f "$file" ]; then
        echo "   📄 Found existing Conky file: $file"
        if [ "$NONINTERACTIVE" = true ]; then
            remove_file="y"
            echo "   ✅ Non-interactive mode: automatically selected 'yes' to backup and remove the file."
        else
            read -p "   ❓ Do you want to backup and remove it? (y/n): " remove_file
        fi
        if [[ "$remove_file" =~ ^[Yy]$ ]]; then
            # Create backup with filename.extension.date.time.backup format
            filename=$(basename "$file")
            cp "$file" "${file}.${BACKUP_TIMESTAMP}.backup" 2>/dev/null
            echo "   💾 Backed up: ${file} → ${file}.${BACKUP_TIMESTAMP}.backup"
            rm -f "$file"
            echo "   🗑️ Removed: $file"
        fi
    fi
done

echo "   ✅ Clean-up process completed."
echo "════════════════════════════════════════════════"

# Check if Conky is installed and install if not
echo "📦 Checking for Conky installation..."

# Check if conkystartup.sh and rm-conkyset.sh are present in this directory and then move them to the home directory
echo "Checking for required scripts in the current directory..."
if [ ! -f "conkystartup.sh" ] || [ ! -f "rm-conkyset.sh" ]; then
    echo "Required scripts not found in the current directory. Please ensure conkystartup.sh and rm-conkyset.sh are present."
    exit 1
else
    echo "Required scripts found in the current directory."
    # Backup existing scripts if they exist before overwriting
    for script in "conkystartup.sh" "rm-conkyset.sh"; do
        if [ -f "$HOME/$script" ]; then
            cp "$HOME/$script" "$HOME/${script}.${BACKUP_TIMESTAMP}.backup" 2>/dev/null
            echo "   💾 Existing $script backed up to: $HOME/${script}.${BACKUP_TIMESTAMP}.backup"
        fi
    done
    # Copy scripts to home directory
    cp conkystartup.sh "$HOME/" || { echo "Failed to copy conkystartup.sh to home directory."; exit 1; }
    cp rm-conkyset.sh "$HOME/" || { echo "Failed to copy rm-conkyset.sh to home directory."; exit 1; }
    echo "Scripts copied to home directory successfully."    
fi

# Check if conky.template.conf exists in this directory
if [ ! -f "conky.template.conf" ]; then
    echo "Conky template configuration file not found in the current directory. Please ensure conky.template.conf is present."
    exit 1
else
    echo "Conky template configuration file found in the current directory."
    # Create .config/conky directory if it doesn't exist
    mkdir -p "$HOME/.config/conky" || { echo "Failed to create .config/conky directory."; exit 1; }

    # Backup existing conky.conf if it exists
    if [ -f "$HOME/.config/conky/conky.conf" ]; then
        cp "$HOME/.config/conky/conky.conf" "$HOME/.config/conky/conky.conf.${BACKUP_TIMESTAMP}.backup" 2>/dev/null
        echo "   💾 Existing conky.conf backed up to: conky.conf.${BACKUP_TIMESTAMP}.backup"
    fi

    # --- Location detection and prompt ---
    LOCATION=""
    DETECTED_LOCATION=""

    echo "🌍 Weather location setup:"
    MAX_ATTEMPTS=2
    OWM_API_KEY="YOUR_OPENWEATHERMAP_API_KEY" # <-- Replace or export this as needed
    
    # Auto-detect location first using ipinfo.io
    echo "   🔍 Auto-detecting your location..."
    if command -v curl >/dev/null 2>&1; then
        GEOINFO=$(curl -s ipinfo.io 2>/dev/null)
        CITY=$(echo "$GEOINFO" | grep '"city"' | sed 's/.*"city": "\([^\"]*\)".*/\1/')
        COUNTRY=$(echo "$GEOINFO" | grep '"country"' | sed 's/.*"country": "\([^\"]*\)".*/\1/')
        if [ -n "$CITY" ] && [ -n "$COUNTRY" ]; then
            DETECTED_LOCATION="$CITY,$COUNTRY"
            echo "   🌐 Detected location: $DETECTED_LOCATION"
        else
            echo "   ⚠️  Could not auto-detect location."
            DETECTED_LOCATION="Budapest,HU"
            echo "   ℹ️  Will use default: $DETECTED_LOCATION"
        fi
    else
        echo "   ⚠️  curl not available for auto-detection."
        DETECTED_LOCATION="Budapest,HU"
        echo "   ℹ️  Will use default: $DETECTED_LOCATION"
    fi

    validate_location() {
        # Validate location using OpenWeatherMap Geocoding API
        if [ -z "$OWM_API_KEY" ] || [ "$OWM_API_KEY" = "YOUR_OPENWEATHERMAP_API_KEY" ]; then
            echo "   ⚠️  No OpenWeatherMap API key set; location validation unavailable."
            return 1
        fi
        local loc="$1"
        local resp=$(curl -s "https://api.openweathermap.org/geo/1.0/direct?q=${loc}&limit=1&appid=${OWM_API_KEY}")
        local found=$(echo "$resp" | grep -c '"lat"')
        if [ "$found" -gt 0 ]; then
            return 0
        else
            return 1
        fi
    }

    get_similar_location() {
        # Suggest a similar location using OpenWeatherMap Geocoding API
        if [ -z "$OWM_API_KEY" ] || [ "$OWM_API_KEY" = "YOUR_OPENWEATHERMAP_API_KEY" ]; then
            echo "$DETECTED_LOCATION"
            return
        fi
        local loc="$1"
        local resp=$(curl -s "https://api.openweathermap.org/geo/1.0/direct?q=${loc}&limit=5&appid=${OWM_API_KEY}")
        local suggestion=$(echo "$resp" | grep -o '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        local country=$(echo "$resp" | grep -o '"country":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ -n "$suggestion" ] && [ -n "$country" ]; then
            echo "$suggestion,$country"
        else
            echo "$DETECTED_LOCATION"
        fi
    }

    # Respect --auto-location by skipping manual prompt
    if [ "$AUTO_LOCATION" = true ]; then
        set_location="n"
        echo "   ℹ️  Auto-location enabled (manual prompt disabled)."
    fi

    if [ "$NONINTERACTIVE" = true ]; then
        LOCATION="$DETECTED_LOCATION"
        echo "   ℹ️  Non-interactive mode: automatically set location to: $LOCATION"
    else
        if [ "$AUTO_LOCATION" = true ]; then
            # Skip asking, will use auto-detected location
            LOCATION="$DETECTED_LOCATION"
        else
            echo ""
            read -p "   ❓ Do you want to manually set your weather location? (y/n, default uses detected: $DETECTED_LOCATION): " set_location
        fi
    fi
    if [[ "$set_location" =~ ^[Yy]$ ]]; then
        ATTEMPT=1
        while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
            echo ""
            echo "   💡 Hint: Detected location is '$DETECTED_LOCATION'"
            read -p "   📍 Enter your city name or city,country (e.g. Budapest,HU) or press Enter for detected location: " LOCATION
            if [ -z "$LOCATION" ]; then
                LOCATION="$DETECTED_LOCATION"
                echo "   ✅ Using detected location: $LOCATION"
                break
            fi
            validate_location "$LOCATION"
            if [ $? -eq 0 ]; then
                echo "   ✅ Location validated: $LOCATION"
                break
            else
                echo "   ❌ Could not validate location: $LOCATION"
                echo "   🔍 Searching for similar valid locations..."
                if [ -z "$OWM_API_KEY" ] || [ "$OWM_API_KEY" = "YOUR_OPENWEATHERMAP_API_KEY" ]; then
                    suggestion_list=("$DETECTED_LOCATION")
                else
                    resp=$(curl -s "https://api.openweathermap.org/geo/1.0/direct?q=${LOCATION}&limit=3&appid=${OWM_API_KEY}")
                    suggestion_list=()
                    for i in 0 1 2; do
                        name=$(echo "$resp" | jq -r ".[$i].name" 2>/dev/null)
                        country=$(echo "$resp" | jq -r ".[$i].country" 2>/dev/null)
                        if [ "$name" != "null" ] && [ "$country" != "null" ] && [ -n "$name" ] && [ -n "$country" ]; then
                            suggestion_list+=("$name,$country")
                        fi
                    done
                    if [ ${#suggestion_list[@]} -eq 0 ]; then
                        suggestion_list=("$DETECTED_LOCATION")
                    fi
                fi
                echo "   💡 Did you mean:"
                for idx in "${!suggestion_list[@]}"; do
                    echo "     $((idx+1)). ${suggestion_list[$idx]}"
                done
                
                # Handle suggestions within the attempt, but don't break the loop unless accepted
                suggestion_accepted=false
                if [ ${#suggestion_list[@]} -gt 1 ]; then
                    read -p "   ❓ Enter the number of the correct location, or press Enter to try again: " loc_choice
                    if [[ "$loc_choice" =~ ^[1-9][0-9]*$ ]] && [ "$loc_choice" -ge 1 ] && [ "$loc_choice" -le ${#suggestion_list[@]} ]; then
                        LOCATION="${suggestion_list[$((loc_choice-1))]}"
                        echo "   ✅ Location selected: $LOCATION"
                        suggestion_accepted=true
                    fi
                else
                    read -p "   ❓ Use this suggestion (${suggestion_list[0]})? (y/n): " use_suggestion
                    if [[ "$use_suggestion" =~ ^[Yy]$ ]]; then
                        LOCATION="${suggestion_list[0]}"
                        echo "   ✅ Location selected: $LOCATION"
                        suggestion_accepted=true
                    fi
                fi
                
                # If suggestion was accepted, break out of the loop
                if [ "$suggestion_accepted" = true ]; then
                    break
                fi
                
                # Check if this was the last attempt
                if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
                    LOCATION="$DETECTED_LOCATION"
                    echo "   ⏭️  Maximum attempts reached. Using detected location: $LOCATION"
                    break
                fi
                echo "   🔁 Please try entering your location again. ($((MAX_ATTEMPTS-ATTEMPT)) attempts left)"
            fi
            ATTEMPT=$((ATTEMPT+1))
        done
    else
        # Use auto-detected location
        LOCATION="$DETECTED_LOCATION"
        echo "   🌐 Using auto-detected location: $LOCATION"
    fi
    # Save location to a variable for template substitution
    if [ -z "$LOCATION" ]; then
        LOCATION="Budapest,HU"
        echo "   ℹ️  Defaulting to: $LOCATION"
    fi
    # Show the final location used for weather
    echo "   📍 Weather location set to: $LOCATION"

    # Detect connected monitors and select head
    MONITOR_INDEX=$(get_monitor_index "$NONINTERACTIVE")
    echo "   ✅ Selected monitor index: $MONITOR_INDEX"

    # Detect active network interface
    echo "   🔍 Detecting active network interface..."
    IFACE=$(get_iface)
    echo "   ✅ Using network interface: $IFACE"
    # Substitute @@IFACE@@, @@LOCATION@@, and @@MONITOR@@ in the template using '|' as delimiter
    sed -e "s|@@IFACE@@|${IFACE}|g" \
        -e "s|@@LOCATION@@|${LOCATION}|g" \
        -e "s|@@MONITOR@@|${MONITOR_INDEX}|g" \
        conky.template.conf > "$HOME/.config/conky/conky.conf" || { echo "Failed to create conky.conf with substitutions."; exit 1; }
    # Ensure the Lua multiline string is properly closed in conky.conf
    # Check that the last line ends with ']];'
    if ! tail -n 1 "$HOME/.config/conky/conky.conf" | grep -qE '\]\];\s*$'; then
        echo ']];' >> "$HOME/.config/conky/conky.conf"
    fi
    echo "   ✅ Configuration file created successfully with interface: $IFACE, location: $LOCATION, monitor: $MONITOR_INDEX"
fi
# Template copied
echo "Conky template configuration file copied successfully."
pause() {
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}


# Ensure scripts are executable
chmod +x "$HOME/conkystartup.sh" || { echo "Failed to make conkystartup.sh executable."; exit 1; }
chmod +x "$HOME/rm-conkyset.sh" || { echo "Failed to make rm-conkyset.sh executable."; exit 1; }
# Check if Conky is installed
echo "Checking if Conky is installed..."

if ! command -v conky &> /dev/null; then
    echo "Conky is not installed. Installing Conky..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y conky || { echo "Failed to install Conky."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu conky || { echo "Failed to install Conky."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y conky || { echo "Failed to install Conky."; exit 1; }
    else
        echo "Package manager not supported. Please install Conky manually."
        exit 1
    fi
    # Start Conky immediately after successful install
    echo "🚀 Launching Conky..."
    "$HOME/conkystartup.sh"
    echo "🎉 Setup complete! Terminal is now free to use."
    echo "📊 Conky should now be visible on your desktop."
    exit 0
else
    echo "✅ Conky is already installed."
fi

# Hardware Detection and Thermal Sensor Check
echo "🔍 Detecting hardware and thermal sensors..."
echo "════════════════════════════════════════════════"

# === GPU detection and related actions (guarded by SKIP_GPU) ===
if [ "$SKIP_GPU" = false ]; then

# Check for video card/GPU
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

# Check for NVIDIA GPU specifically
nvidia_detected=false
amd_detected=false
intel_detected=false

if command -v nvidia-smi >/dev/null 2>&1; then
    echo "   ✅ NVIDIA GPU detected with nvidia-smi support"
    nvidia_temp=$(nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader 2>/dev/null | head -1)
    if [ -n "$nvidia_temp" ]; then
        echo "   📊 NVIDIA GPU: $nvidia_temp"
    fi
    nvidia_detected=true
else
    # Check if NVIDIA GPU exists but nvidia-smi is not installed
    if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "nvidia\|geforce\|quadro\|tesla"; then
        echo "   ⚠️  NVIDIA GPU detected but nvidia-smi not available"
        nvidia_detected=true
    fi
fi

# Check for AMD GPU
if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "\bamd\b\|\bradeon\b\|\bati\b"; then
    echo "   🔴 AMD GPU detected"
    amd_detected=true
    if command -v radeontop >/dev/null 2>&1; then
        echo "   ✅ radeontop available for AMD monitoring"
    else
        echo "   ⚠️  radeontop not installed for AMD monitoring"
    fi
fi

# Check for Intel GPU
if [ -n "$gpu_info" ] && echo "$gpu_info" | grep -qi "intel.*\(graphics\|vga\|controller\)"; then
    echo "   🔵 Intel GPU detected"
    intel_detected=true
    if command -v intel_gpu_top >/dev/null 2>&1; then
        echo "   ✅ intel_gpu_top available for Intel monitoring"
    else
        echo "   ℹ️  intel_gpu_top not installed for Intel monitoring"
    fi
fi

# Show detection summary
echo ""
echo "   📋 Detection Summary:"
echo "   • NVIDIA: $([ "$nvidia_detected" = true ] && echo "✅ Yes" || echo "❌ No")"
echo "   • AMD: $([ "$amd_detected" = true ] && echo "✅ Yes" || echo "❌ No")"  
echo "   • Intel: $([ "$intel_detected" = true ] && echo "✅ Yes" || echo "❌ No")"

# GPU Driver Installation Section
gpu_drivers_needed=false
echo "🎮 GPU Driver Detection & Installation"
echo "════════════════════════════════════════════════"

# NVIDIA Driver Detection and Installation
if [ "$nvidia_detected" = true ]; then
    echo "🟢 NVIDIA GPU Detected - Checking drivers..."
    
    # Check if any NVIDIA driver is loaded
    nvidia_driver_loaded=false
    nvidia_driver_version=""
    
    if lsmod | grep -q nvidia; then
        nvidia_driver_loaded=true
        if command -v nvidia-smi >/dev/null 2>&1; then
            nvidia_driver_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)
            echo "   ✅ NVIDIA driver loaded (version: ${nvidia_driver_version:-unknown})"
        else
            echo "   ⚠️  NVIDIA driver loaded but nvidia-smi not available"
        fi
    else
        echo "   ❌ No NVIDIA driver loaded"
        gpu_drivers_needed=true
    fi
    
    # Get recommended drivers using ubuntu-drivers
    if command -v ubuntu-drivers >/dev/null 2>&1; then
        echo "   🔍 Checking available NVIDIA drivers..."
        recommended_driver=$(ubuntu-drivers devices 2>/dev/null | grep "nvidia-driver.*recommended" | awk '{print $3}')
        available_drivers=$(ubuntu-drivers devices 2>/dev/null | grep "nvidia-driver" | awk '{print $3}' | sort -u)
        
        if [ -n "$recommended_driver" ]; then
            echo "   💡 Recommended driver: $recommended_driver"
        fi
        
        if [ -n "$available_drivers" ]; then
            echo "   📋 Available drivers:"
            echo "$available_drivers" | while read -r driver; do
                if [[ "$driver" == *"recommended"* ]]; then
                    echo "   • $driver (⭐ recommended)"
                else
                    echo "   • $driver"
                fi
            done
        fi
        
        # Check if current driver matches recommended driver
        current_driver_matches_recommended=false
        if [ "$nvidia_driver_loaded" = true ] && [ -n "$recommended_driver" ] && [ -n "$nvidia_driver_version" ]; then
            # Extract version number from recommended driver (e.g., nvidia-driver-570 -> 570)
            recommended_version=$(echo "$recommended_driver" | grep -o '[0-9]\+')
            # Check if current driver version starts with recommended version
            if [[ "$nvidia_driver_version" == "$recommended_version"* ]]; then
                current_driver_matches_recommended=true
            fi
        fi
        
        # Offer to install driver if none loaded or user wants to upgrade
        if [ "$nvidia_driver_loaded" = false ]; then
            echo ""
            echo "🚨 No NVIDIA driver detected!"
            echo "   Without proper drivers, your GPU won't function optimally."
            if [ "$NONINTERACTIVE" = true ]; then
                install_nvidia_driver="y"
                echo "   ✅ Non-interactive mode: automatically selected 'yes' to install the recommended NVIDIA driver."
            else
                read -p "📥 Do you want to install the recommended NVIDIA driver? (y/n): " install_nvidia_driver
            fi
        elif [ "$current_driver_matches_recommended" = true ]; then
            echo ""
            echo "✅ Current NVIDIA driver is up to date!"
            echo "   Current: ${nvidia_driver_version} (matches recommended: $recommended_driver)"
            echo "   No driver update needed."
            install_nvidia_driver="n"
        elif [ -n "$recommended_driver" ]; then
            echo ""
            echo "💡 Current driver: ${nvidia_driver_version:-unknown}"
            echo "   Recommended: $recommended_driver"
            if [ "$NONINTERACTIVE" = true ]; then
                install_nvidia_driver="y"
                echo "   ✅ Non-interactive mode: automatically selected 'yes' to install/update to the recommended driver."
            else
                read -p "📥 Do you want to install/update to the recommended driver? (y/n): " install_nvidia_driver
            fi
        else
            install_nvidia_driver="n"
        fi
        
        if [[ "$install_nvidia_driver" =~ ^[Yy]$ ]]; then
            echo "🔄 Installing NVIDIA drivers..."
            echo "⚠️  Note: A reboot will be required after installation!"
            
            if [ -n "$recommended_driver" ]; then
                sudo apt update
                sudo apt install -y "$recommended_driver" || echo "⚠️  Failed to install $recommended_driver"
            else
                sudo ubuntu-drivers autoinstall || echo "⚠️  Failed to auto-install drivers"
            fi
            
            echo "✅ NVIDIA driver installation completed"
            echo "🔄 Please reboot your system to activate the new drivers"
            echo "💡 After reboot, GPU temperature monitoring will be available"
        elif [[ "$install_nvidia_driver" =~ ^[Nn]$ ]] && [ "$current_driver_matches_recommended" = false ] && [ "$nvidia_driver_loaded" = true ]; then
            echo "⏭️  Skipping NVIDIA driver installation"
        fi
    else
        echo "   ⚠️  ubuntu-drivers not available, manual installation required"
        if [ "$nvidia_driver_loaded" = false ]; then
            echo "   💡 You can manually install drivers with:"
            echo "   sudo apt install nvidia-driver-570"
            echo "   (or your preferred version)"
        fi
    fi
    echo ""
fi

# AMD Driver Detection and Installation
if [ "$amd_detected" = true ]; then
    echo "🔴 AMD GPU Detected - Checking drivers..."
    
    # Check if AMD drivers are loaded
    amd_driver_loaded=false
    if lsmod | grep -E "(amdgpu|radeon)" >/dev/null; then
        amd_driver_loaded=true
        if lsmod | grep amdgpu >/dev/null; then
            echo "   ✅ AMD GPU driver (amdgpu) loaded"
        elif lsmod | grep radeon >/dev/null; then
            echo "   ✅ AMD GPU driver (radeon) loaded"
        fi
    else
        echo "   ❌ No AMD GPU driver loaded"
        gpu_drivers_needed=true
    fi
    
    # AMD driver installation/check
    if [ "$amd_driver_loaded" = false ]; then
        echo "🚨 No AMD driver detected!"
        echo "   Modern AMD GPUs use the amdgpu driver (usually built into kernel)"
        echo "   For optimal performance, ensure mesa drivers are installed"
        if [ "$NONINTERACTIVE" = true ]; then
            install_amd_driver="y"
            echo "   ✅ Non-interactive mode: automatically selected 'yes' to install AMD Mesa drivers and utilities."
        else
            read -p "📥 Do you want to install AMD Mesa drivers and utilities? (y/n): " install_amd_driver
        fi
        
        if [[ "$install_amd_driver" =~ ^[Yy]$ ]]; then
            echo "🔄 Installing AMD Mesa drivers and utilities..."
            if command -v apt-get &> /dev/null; then
                sudo apt update
                sudo apt install -y mesa-vulkan-drivers mesa-utils vulkan-tools || echo "⚠️  Failed to install AMD Mesa drivers"
                # Also install firmware if available
                sudo apt install -y firmware-amd-graphics || echo "ℹ️  AMD firmware may already be installed"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S mesa vulkan-radeon mesa-utils vulkan-tools || echo "⚠️  Failed to install AMD drivers"
            elif command -v dnf &> /dev/null; then
                sudo dnf install mesa-vulkan-drivers mesa-utils vulkan-tools || echo "⚠️  Failed to install AMD drivers"
            fi
            echo "✅ AMD driver installation completed"
        else
            echo "⏭️  Skipping AMD driver installation"
        fi
    else
        # Check if Mesa drivers are properly installed
        if ! command -v glxinfo >/dev/null 2>&1; then
            echo "   💡 Consider installing mesa-utils for better GPU diagnostics"
            if [ "$NONINTERACTIVE" = true ]; then
                install_mesa_utils="y"
                echo "   ✅ Non-interactive mode: automatically selected 'yes' to install mesa-utils."
            else
                read -p "📥 Install mesa-utils for AMD GPU diagnostics? (y/n): " install_mesa_utils
            fi
            if [[ "$install_mesa_utils" =~ ^[Yy]$ ]]; then
                sudo apt install -y mesa-utils || echo "⚠️  Failed to install mesa-utils"
            fi
        fi
    fi
    echo ""
fi

# Intel Driver Detection and Installation
if [ "$intel_detected" = true ]; then
    echo "🔵 Intel GPU Detected - Checking drivers..."
    
    # Intel drivers are usually built into the kernel
    intel_driver_loaded=false
    if lsmod | grep -E "(i915|xe)" >/dev/null; then
        intel_driver_loaded=true
        if lsmod | grep i915 >/dev/null; then
            echo "   ✅ Intel GPU driver (i915) loaded"
        elif lsmod | grep xe >/dev/null; then
            echo "   ✅ Intel GPU driver (xe) loaded"
        fi
    else
        echo "   ⚠️  Intel GPU driver may not be loaded"
    fi
    
    # Intel driver enhancement
    echo "   💡 Intel GPUs use built-in kernel drivers"
    echo "   For optimal performance, consider installing Intel media drivers"
    if [ "$NONINTERACTIVE" = true ]; then
        install_intel_enhancement="y"
        echo "   ✅ Non-interactive mode: automatically selected 'yes' to install Intel GPU enhancement packages."
    else
        read -p "📥 Install Intel GPU enhancement packages? (y/n): " install_intel_enhancement
    fi
    
    if [[ "$install_intel_enhancement" =~ ^[Yy]$ ]]; then
        echo "🔄 Installing Intel GPU enhancement packages..."
        if command -v apt-get &> /dev/null; then
            sudo apt update
            sudo apt install -y intel-media-va-driver vainfo mesa-utils || echo "⚠️  Failed to install Intel enhancement packages"
        elif command -v pacman &> /dev/null; then
            sudo pacman -S intel-media-driver mesa-utils || echo "⚠️  Failed to install Intel packages"
        elif command -v dnf &> /dev/null; then
            sudo dnf install intel-media-driver mesa-utils || echo "⚠️  Failed to install Intel packages"
        fi
        echo "✅ Intel GPU enhancement installation completed"
    else
        echo "⏭️  Skipping Intel GPU enhancements"
    fi
    echo ""
fi

# GPU Monitoring Tools Installation Prompt
gpu_tools_needed=false
if [ "$nvidia_detected" = true ] && ! command -v nvidia-smi >/dev/null 2>&1; then
    gpu_tools_needed=true
fi
if [ "$amd_detected" = true ] && ! command -v radeontop >/dev/null 2>&1; then
    gpu_tools_needed=true
fi
if [ "$intel_detected" = true ] && ! command -v intel_gpu_top >/dev/null 2>&1; then
    gpu_tools_needed=true
fi

# Only show installation section if GPU tools are actually needed
if [ "$gpu_tools_needed" = true ]; then
    echo "🎮 GPU Monitoring Tools Installation"
    echo "════════════════════════════════════════════════"
    
    # NVIDIA GPU tools
    if [ "$nvidia_detected" = true ] && ! command -v nvidia-smi >/dev/null 2>&1; then
        echo "🟢 NVIDIA GPU detected without monitoring tools"
        echo "   Recommended: nvidia-utils package for temperature monitoring"
        echo "   This will enable GPU temperature display in Conky"
        echo ""
        if [ "$NONINTERACTIVE" = true ]; then
            install_nvidia="y"
            echo "   ✅ Non-interactive mode: automatically selected 'yes' to install NVIDIA monitoring tools."
        else
            read -p "📥 Do you want to install NVIDIA monitoring tools? (y/n): " install_nvidia
        fi
        if [[ "$install_nvidia" =~ ^[Yy]$ ]]; then
            echo "🔄 Installing NVIDIA monitoring tools..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y nvidia-utils-* || echo "⚠️  Failed to install nvidia-utils. Try: sudo apt install nvidia-utils"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S nvidia-utils || echo "⚠️  Failed to install nvidia-utils"
            elif command -v dnf &> /dev/null; then
                sudo dnf install nvidia-settings || echo "⚠️  Failed to install nvidia-settings"
            else
                echo "⚠️  Please install nvidia-utils manually for your distribution"
            fi
        else
            echo "⏭️  Skipping NVIDIA tools installation"
        fi
        echo ""
    fi
    
    # AMD GPU tools
    if [ "$amd_detected" = true ] && ! command -v radeontop >/dev/null 2>&1; then
        echo "🔴 AMD GPU detected without monitoring tools"
        echo "   Recommended: radeontop package for GPU monitoring"
        echo "   This will enable GPU usage and temperature monitoring"
        echo ""
        if [ "$NONINTERACTIVE" = true ]; then
            install_amd="y"
            echo "   ✅ Non-interactive mode: automatically selected 'yes' to install AMD monitoring tools."
        else
            read -p "📥 Do you want to install AMD monitoring tools? (y/n): " install_amd
        fi
        if [[ "$install_amd" =~ ^[Yy]$ ]]; then
            echo "🔄 Installing AMD monitoring tools..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y radeontop || echo "⚠️  Failed to install radeontop"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S radeontop || echo "⚠️  Failed to install radeontop"
            elif command -v dnf &> /dev/null; then
                sudo dnf install radeontop || echo "⚠️  Failed to install radeontop"
            else
                echo "⚠️  Please install radeontop manually for your distribution"
            fi
        else
            echo "⏭️  Skipping AMD tools installation"
        fi
        echo ""
    fi
    
    # Intel GPU tools
    if [ "$intel_detected" = true ] && ! command -v intel_gpu_top >/dev/null 2>&1; then
        echo "🔵 Intel GPU detected without advanced monitoring tools"
        echo "   Optional: intel-gpu-tools package for detailed GPU monitoring"
        echo "   Note: Basic temperature monitoring works without this"
        echo ""
        if [ "$NONINTERACTIVE" = true ]; then
            install_intel="y"
            echo "   ✅ Non-interactive mode: automatically selected 'yes' to install Intel GPU monitoring tools."
        else
            read -p "📥 Do you want to install Intel GPU monitoring tools? (y/n): " install_intel
        fi
        if [[ "$install_intel" =~ ^[Yy]$ ]]; then
            echo "🔄 Installing Intel GPU monitoring tools..."
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y intel-gpu-tools || echo "⚠️  Failed to install intel-gpu-tools"
            elif command -v pacman &> /dev/null; then
                sudo pacman -S intel-gpu-tools || echo "⚠️  Failed to install intel-gpu-tools"
            elif command -v dnf &> /dev/null; then
                sudo dnf install intel-gpu-tools || echo "⚠️  Failed to install intel-gpu-tools"
            else
                echo "⚠️  Please install intel-gpu-tools manually for your distribution"
            fi
        else
            echo "⏭️  Skipping Intel tools installation"
        fi
        echo ""
    fi
    echo "════════════════════════════════════════════════"
    echo ""
fi  # end SKIP_GPU guard

# === Sensor detection and related actions (guarded by SKIP_SENSOR) ===
if [ "$SKIP_SENSOR" = false ]; then

echo ""
echo "🌡️  Thermal Sensor Detection:"
if command -v sensors >/dev/null 2>&1; then
    echo "   ✅ lm-sensors package available"
    sensor_count=$(sensors 2>/dev/null | grep -c "°C")
    if [ "$sensor_count" -gt 0 ]; then
        echo "   📊 Found $sensor_count temperature sensors"
        echo "   Available sensors:"
        sensors 2>/dev/null | grep -E "(Adapter|temp|°C)" | while read -r line; do
            echo "   • $line"
        done
    else
        echo "   ⚠️  No temperature sensors detected by lm-sensors"
    fi
else
    echo "   ⚠️  lm-sensors not installed, limited temperature monitoring"
fi

# Check hardware monitoring interfaces
echo ""
echo "🔧 Hardware Monitoring Interfaces:"
hwmon_count=0
for hwmon in /sys/class/hwmon/hwmon*/name; do
    if [ -f "$hwmon" ]; then
        hwmon_name=$(cat "$hwmon" 2>/dev/null)
        hwmon_num=$(echo "$hwmon" | grep -o 'hwmon[0-9]*')
        echo "   • $hwmon_num: $hwmon_name"
        hwmon_count=$((hwmon_count + 1))
    fi
done

if [ "$hwmon_count" -eq 0 ]; then
    echo "   ⚠️  No hwmon interfaces found"
else
    echo "   ✅ Found $hwmon_count hardware monitoring interfaces"
fi

# Check thermal zones
thermal_zones=$(ls /sys/class/thermal/thermal_zone*/temp 2>/dev/null | wc -l)
if [ "$thermal_zones" -gt 0 ]; then
    echo "   🌡️  Found $thermal_zones thermal zones"
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$zone" ]; then
            zone_num=$(echo "$zone" | grep -o 'thermal_zone[0-9]*')
            temp=$(awk '{printf "%.1f", $1/1000}' "$zone" 2>/dev/null)
            echo "   • $zone_num: ${temp}°C"
        fi
    done
else
    echo "   ⚠️  No thermal zones found"
fi

echo "════════════════════════════════════════════════"
echo ""
fi  # end SKIP_SENSOR guard

# Offer lm-sensors installation only when sensors missing and not skipped
if [ "$SKIP_SENSOR" = false ] && ! command -v sensors >/dev/null 2>&1; then
    echo "🌡️  lm-sensors not detected"
    echo "   Recommended: lm-sensors package for comprehensive temperature monitoring"
    echo "   This enables CPU, motherboard, and other sensor monitoring"
    echo ""
    if [ "$NONINTERACTIVE" = true ]; then
        install_sensors="y"
        echo "   ✅ Non-interactive mode: automatically selected 'yes' to install lm-sensors."
    else
        read -p "📥 Do you want to install lm-sensors? (y/n): " install_sensors
    fi
    if [[ "$install_sensors" =~ ^[Yy]$ ]]; then
        echo "🔄 Installing lm-sensors..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y lm-sensors || echo "⚠️  Failed to install lm-sensors"
            echo "🔧 Running sensors-detect to configure sensors..."
            sudo sensors-detect --auto 2>/dev/null || echo "ℹ️  Please run 'sudo sensors-detect' manually later"
        elif command -v pacman &> /dev/null; then
            sudo pacman -S lm_sensors || echo "⚠️  Failed to install lm_sensors"
        elif command -v dnf &> /dev/null; then
            sudo dnf install lm_sensors || echo "⚠️  Failed to install lm_sensors"
        else
            echo "⚠️  Please install lm-sensors manually for your distribution"
        fi
    else
        echo "⏭️  Skipping lm-sensors installation"
    fi
    echo ""
fi

# Desktop Environment Detection and Autostart Creation
echo "🔍 Detecting desktop environment..."
DESKTOP_ENV=""
AUTOSTART_DELAY="5"

# Detect desktop environment
if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    DESKTOP_ENV="$XDG_CURRENT_DESKTOP"
elif [ -n "$DESKTOP_SESSION" ]; then
    DESKTOP_ENV="$DESKTOP_SESSION"
elif command -v gnome-session >/dev/null 2>&1; then
    DESKTOP_ENV="GNOME"
elif command -v cinnamon-session >/dev/null 2>&1; then
    DESKTOP_ENV="X-Cinnamon"
elif command -v mate-session >/dev/null 2>&1; then
    DESKTOP_ENV="MATE"
elif command -v xfce4-session >/dev/null 2>&1; then
    DESKTOP_ENV="XFCE"
elif command -v lxsession >/dev/null 2>&1; then
    DESKTOP_ENV="LXDE"
elif command -v startplasma-x11 >/dev/null 2>&1 || command -v startplasma-wayland >/dev/null 2>&1; then
    DESKTOP_ENV="KDE"
else
    DESKTOP_ENV="Unknown"
fi

echo "   📋 Detected Desktop Environment: $DESKTOP_ENV"

# Create autostart entry based on desktop environment
echo "🚀 Creating autostart entry for Conky..."
mkdir -p "$HOME/.config/autostart"
AUTOSTART_FILE="$HOME/.config/autostart/conky.desktop"

# Create base desktop entry
cat > "$AUTOSTART_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Conky System Monitor
Comment=Start Conky system monitor at login
Hidden=false
NoDisplay=false
StartupNotify=false
Terminal=false
Categories=System;Monitor;
EOF

# Add desktop environment specific configurations
case "$DESKTOP_ENV" in
    "X-Cinnamon"|"CINNAMON"|*"Cinnamon"*)
        echo "   🟢 Configuring for Cinnamon desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=$HOME/conkystartup.sh
X-GNOME-Autostart-enabled=true
EOF
        ;;
    "GNOME"|*"GNOME"*|"ubuntu:GNOME"|"pop:GNOME")
        echo "   🔵 Configuring for GNOME desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
X-GNOME-Autostart-enabled=true
X-GNOME-Autostart-Delay=$AUTOSTART_DELAY
EOF
        ;;
    "KDE"|"plasma"|*"KDE"*|*"Plasma"*)
        echo "   🟠 Configuring for KDE Plasma desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
X-KDE-autostart-after=panel
X-KDE-StartupNotify=false
EOF
        ;;
    "XFCE"|"xfce"|*"XFCE"*)
        echo "   🟡 Configuring for XFCE desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
X-XFCE-Autostart-enabled=true
EOF
        ;;
    "MATE"|*"MATE"*)
        echo "   🟤 Configuring for MATE desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
X-GNOME-Autostart-enabled=true
X-MATE-Autostart-enabled=true
EOF
        ;;
    "LXDE"|"LXQt"|*"LXDE"*|*"LXQt"*)
        echo "   🔘 Configuring for LXDE/LXQt desktop..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
EOF
        ;;
    *)
        echo "   ⚠️  Unknown desktop environment, using generic configuration..."
        cat >> "$AUTOSTART_FILE" << EOF
Exec=bash -c "sleep $AUTOSTART_DELAY && $HOME/conkystartup.sh"
X-GNOME-Autostart-enabled=true
EOF
        ;;
esac

echo "✅ Autostart entry created at $AUTOSTART_FILE"
echo "   ⏱️  Configured with ${AUTOSTART_DELAY}-second startup delay"
echo "   🖥️  Optimized for $DESKTOP_ENV desktop environment"


echo ""
echo "════════════════════════════════════════════════"
echo "🎉 Conky setup completed successfully!"
echo "💡 You can start Conky manually by running: ~/conkystartup.sh"
echo "🚀 Conky will start automatically on next login."
echo "⚙️  Configuration files are in $HOME/.config/conky/"
echo "🗑️  To uninstall, run: ~/rm-conkyset.sh"
echo "════════════════════════════════════════════════"
echo "📝 To remove the autostart entry, delete: $HOME/.config/autostart/conky.desktop"
echo "📝 To remove the Conky configuration files, delete: $HOME/.config/conky/"
echo "📝 To run this setup script again, execute: $HOME/conkyset.sh"
echo "📝 To check if Conky is running: pgrep conky"
echo "📝 To check Conky logs, see terminal output or log files if configured."
echo "📝 To check Conky configuration: conky -c $HOME/.config/conky/conky.conf"
echo "📝 To check Conky version: conky --version"
echo "Have fun! - Gyurus"

# Add clear feedback and prompt before starting Conky
echo ""
echo "════════════════════════════════════════════════"
echo "Ready to launch Conky!"
echo "If you want to review the configuration or make changes, do so now."
echo "Press ENTER to start Conky, or Ctrl+C to cancel."
read -r _
echo "🚀 Launching Conky..."
if "$HOME/conkystartup.sh"; then
    echo "🎉 Conky started successfully!"
    echo "📊 You should now see Conky on your desktop."
else
    echo "❌ Failed to start Conky. Please check your configuration or run ~/conkystartup.sh manually."
fi
echo "════════════════════════════════════════════════"

fi



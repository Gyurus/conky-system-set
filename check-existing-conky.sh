#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                Conky Installation Checker                   ║"
echo "║                   SYSTEM SCAN UTILITY                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Define colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if a file exists and print result
check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✅ Found:${NC} $1"
        return 0
    else
        echo -e "${RED}❌ Not found:${NC} $1"
        return 1
    fi
}

# Function to check if a directory exists and print result
check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✅ Found directory:${NC} $1"
        local file_count=$(find "$1" -type f | wc -l)
        echo -e "   ${BLUE}Contains ${file_count} files${NC}"
        return 0
    else
        echo -e "${RED}❌ Not found:${NC} $1"
        return 1
    fi
}

# Function to check if a package is installed
check_package() {
    if command -v "$1" &> /dev/null; then
        echo -e "${GREEN}✅ Installed:${NC} $1 $(command -v "$1")"
        return 0
    else
        echo -e "${RED}❌ Not installed:${NC} $1"
        return 1
    fi
}

# Function to check for running processes
check_process() {
    if pgrep "$1" &> /dev/null; then
        local pid=$(pgrep "$1")
        echo -e "${GREEN}✅ Running:${NC} $1 (PID: $pid)"
        return 0
    else
        echo -e "${RED}❌ Not running:${NC} $1"
        return 1
    fi
}

# Check for Conky installation
echo -e "${BLUE}🔍 Checking for Conky installation...${NC}"
check_package "conky"
if [ $? -eq 0 ]; then
    echo -e "   ${BLUE}Conky version:${NC} $(conky --version | head -1)"
fi
echo ""

# Check for running Conky processes
echo -e "${BLUE}🔍 Checking for running Conky processes...${NC}"
check_process "conky"
echo ""

# Check for Conky configuration files in standard locations
echo -e "${BLUE}🔍 Checking for Conky configuration files...${NC}"
check_dir "$HOME/.config/conky"
if [ $? -eq 0 ]; then
    echo "   ${YELLOW}Configuration files in ~/.config/conky:${NC}"
    for file in "$HOME/.config/conky"/*; do
        if [ -f "$file" ]; then
            echo "   - $(basename "$file") ($(stat -c %s "$file") bytes, modified $(stat -c %y "$file" | cut -d' ' -f1))"
        fi
    done
fi

check_file "$HOME/.conkyrc"
check_file "/etc/conky/conky.conf"
echo ""

# Check for autostart configurations
echo -e "${BLUE}🔍 Checking for Conky autostart entries...${NC}"
check_file "$HOME/.config/autostart/conky.desktop"
if [ $? -eq 0 ]; then
    echo -e "   ${YELLOW}Autostart configuration:${NC}"
    grep -E "^Exec" "$HOME/.config/autostart/conky.desktop" | sed 's/^/   /'
fi
echo ""

# Check for our script files
echo -e "${BLUE}🔍 Checking for our script files...${NC}"
check_file "$HOME/conkystartup.sh"
check_file "$HOME/rm-conkyset.sh"
echo ""

# Check for environment-specific configurations
echo -e "${BLUE}🔍 Checking for desktop environment...${NC}"
if [ -n "$XDG_CURRENT_DESKTOP" ]; then
    echo -e "${GREEN}✅ Desktop environment:${NC} $XDG_CURRENT_DESKTOP"
elif [ -n "$DESKTOP_SESSION" ]; then
    echo -e "${GREEN}✅ Desktop session:${NC} $DESKTOP_SESSION"
else
    echo -e "${YELLOW}⚠️ Could not detect desktop environment.${NC}"
fi
echo ""

# Check for GPU and monitoring tools
echo -e "${BLUE}🔍 Checking for GPU and monitoring tools...${NC}"
# NVIDIA
if lspci | grep -i "nvidia\|geforce" &> /dev/null; then
    echo -e "${GREEN}✅ NVIDIA GPU detected${NC}"
    check_package "nvidia-smi"
    check_package "nvidia-settings"
fi

# AMD
if lspci | grep -i "amd\|radeon" &> /dev/null; then
    echo -e "${GREEN}✅ AMD GPU detected${NC}"
    check_package "radeontop"
fi

# Intel
if lspci | grep -i "intel.*graphics" &> /dev/null; then
    echo -e "${GREEN}✅ Intel GPU detected${NC}"
    check_package "intel_gpu_top"
fi

# Sensor tools
check_package "sensors"
if [ $? -eq 0 ]; then
    sensor_count=$(sensors 2>/dev/null | grep -c "°C")
    echo -e "   ${BLUE}Found ${sensor_count} temperature sensors${NC}"
fi
echo ""

# Summary
echo -e "${BLUE}════════════════════════════════════════════════${NC}"
echo -e "${BLUE}📋 Summary${NC}"
echo ""

if check_process "conky" &> /dev/null; then
    echo -e "${GREEN}✅ Conky is currently running${NC}"
else
    echo -e "${YELLOW}⚠️ Conky is not currently running${NC}"
fi

if check_dir "$HOME/.config/conky" &> /dev/null || check_file "$HOME/.conkyrc" &> /dev/null; then
    echo -e "${GREEN}✅ Conky configuration files exist${NC}"
else
    echo -e "${RED}❌ No Conky configuration files found${NC}"
fi

if check_file "$HOME/.config/autostart/conky.desktop" &> /dev/null; then
    echo -e "${GREEN}✅ Conky is set to autostart${NC}"
else
    echo -e "${YELLOW}⚠️ Conky is not set to autostart${NC}"
fi

if check_file "$HOME/conkystartup.sh" &> /dev/null && check_file "$HOME/rm-conkyset.sh" &> /dev/null; then
    echo -e "${GREEN}✅ Conky management scripts are installed${NC}"
else
    echo -e "${YELLOW}⚠️ Conky management scripts are not fully installed${NC}"
fi

echo ""
echo -e "${BLUE}You can now proceed with the installation or update${NC}"
echo -e "${BLUE}using ./conkyset.sh if you wish to install or update Conky.${NC}"

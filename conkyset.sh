#!/bin/bash
# linux
# Start prechecks
echo "Starting prechecks for Conky setup..."
# Ensure necessary folders exist
echo "Creating necessary directories..."
mkdir -p "$HOME/.config/conky"
mkdir -p "$HOME/.config/autostart"
echo "Directories created successfully."
echo ""
# Ensure user config directories exist
#ask user if want to install or uninstall conky settings
echo "Welcome to the Conky setup script!"
echo "This script will help you set up Conky on your system."
echo "Do you want to install or uninstall Conky settings? (install/uninstall)"
read -r action
if [[ "$action" == "uninstall" ]]; then
    echo "Uninstalling Conky settings..."
    # Remove autostart entry
    if [ -f "$HOME/.config/autostart/conky.desktop" ]; then
        rm "$HOME/.config/autostart/conky.desktop"
        echo "Autostart entry removed."
    else
        echo "No autostart entry found."
    fi
    # Remove Conky configuration files
    if [ -d "$HOME/.config/conky/" ]; then
        rm -rf "$HOME/.config/conky/"
        echo "Conky configuration files removed."
    else
        echo "No Conky configuration files found."
    fi
    # Remove conkystartup.sh script
    if [ -f "$HOME/conkystartup.sh" ]; then
        rm "$HOME/conkystartup.sh"
        echo "Conky startup script removed."
    else
        echo "No Conky startup script found."
    fi
    echo "Conky settings uninstalled successfully!"
    echo ""
    exit 0
fi
# Check if wget is installed
echo "Checking if wget is installed..."
echo ""

if ! command -v wget &> /dev/null; then
    echo "wget is not installed. Installing wget..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y wget || { echo "Failed to install wget."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu wget || { echo "Failed to install wget."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y wget || { echo "Failed to install wget."; exit 1; }
    else
        echo "Package manager not supported. Please install wget manually."
        exit 1
    fi
else
    echo "wget is already installed."
fi
# Check if git is installed
echo "Checking if git is installed..."
if ! command -v git &> /dev/null; then
    echo "git is not installed. Installing git..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y git || { echo "Failed to install git."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu git || { echo "Failed to install git."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y git || { echo "Failed to install git."; exit 1; }
    else
        echo "Package manager not supported. Please install git manually."
        exit 1
    fi
else
    echo "git is already installed."
fi
# Check if curl is installed
echo "Checking if curl is installed..."
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Installing curl..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y curl || { echo "Failed to install curl."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu curl || { echo "Failed to install curl."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y curl || { echo "Failed to install curl."; exit 1; }
    else
        echo "Package manager not supported. Please install curl manually."
        exit 1
    fi
else
    echo "curl is already installed."
fi
# Check if unzip is installed
echo "Checking if unzip is installed..."
if ! command -v unzip &> /dev/null; then
    echo "unzip is not installed. Installing unzip..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y unzip || { echo "Failed to install unzip."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu unzip || { echo "Failed to install unzip."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y unzip || { echo "Failed to install unzip."; exit 1; }
    else
        echo "Package manager not supported. Please install unzip manually."
        exit 1
    fi
else
    echo "unzip is already installed."
fi
# Check if xdg-open is installed
echo "Checking if xdg-open is installed..."
if ! command -v xdg-open &> /dev/null; then
    echo "xdg-open is not installed. Installing xdg-utils..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y xdg-utils || { echo "Failed to install xdg-utils."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu xdg-utils || { echo "Failed to install xdg-utils."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y xdg-utils || { echo "Failed to install xdg-utils."; exit 1; }
    else
        echo "Package manager not supported. Please install xdg-utils manually."
        exit 1
    fi
else
    echo "xdg-open is already installed."
fi
# Check if jq is installed
echo "Checking if jq is installed..."
if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y jq || { echo "Failed to install jq."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu jq || { echo "Failed to install jq."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y jq || { echo "Failed to install jq."; exit 1; }
    else
        echo "Package manager not supported. Please install jq manually."
        exit 1
    fi
else
    echo "jq is already installed."
fi
# Check if xterm is installed
echo "Checking if xterm is installed..."
if ! command -v xterm &> /dev/null; then
    echo "xterm is not installed. Installing xterm..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y xterm || { echo "Failed to install xterm."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu xterm || { echo "Failed to install xterm."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y xterm || { echo "Failed to install xterm."; exit 1; }
    else
        echo "Package manager not supported. Please install xterm manually."
        exit 1
    fi
else
    echo "xterm is already installed."
fi
# Check if xdg-user-dirs is installed
echo "Checking if xdg-user-dirs is installed..."
if ! command -v xdg-user-dirs-update &> /dev/null; then
    echo "xdg-user-dirs is not installed. Installing xdg-user-dirs..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y xdg-user-dirs || { echo "Failed to install xdg-user-dirs."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu xdg-user-dirs || { echo "Failed to install xdg-user-dirs."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y xdg-user-dirs || { echo "Failed to install xdg-user-dirs."; exit 1; }
    else
        echo "Package manager not supported. Please install xdg-user-dirs manually."
        exit 1
    fi
else
    echo "xdg-user-dirs is already installed."
fi
# Check if xdg-user-dirs-update is needed
echo "Checking if xdg-user-dirs-update is needed..."
if [ ! -d "$HOME/.config/user-dirs.dirs" ]; then
    echo "xdg-user-dirs configuration not found. Running xdg-user-dirs-update..."
    xdg-user-dirs-update || { echo "Failed to update user directories."; exit 1; }
else
    echo "xdg-user-dirs configuration already exists."
fi
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
else
    echo "Conky is already installed."
fi

# Ensure pip or pip3 is installed
echo "Checking if pip or pip3 is installed..."
if ! command -v pip &> /dev/null && ! command -v pip3 &> /dev/null; then
    echo "pip and pip3 are not installed. Installing python3-pip..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y python3-pip || { echo "Failed to install python3-pip."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu python-pip || { echo "Failed to install python-pip."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip || { echo "Failed to install python3-pip."; exit 1; }
    else
        echo "Package manager not supported. Please install python3-pip manually."
        exit 1
    fi
else
    echo "pip or pip3 is already installed."
fi

# copy conkystartup.sh to home directory if it doesn't exist
echo "Checking if conkystartup.sh exists in home directory..."
if [ ! -f "$HOME/conkystartup.sh" ]; then
    echo "Conky startup script not found in home directory. Downloading..."
    wget -O "$HOME/conkystartup.sh" "https://raw.githubusercontent.com/Gyurus/conky/main/conkystartup.sh" || { echo "Failed to download conkystartup.sh."; exit 1; }
else
    echo "Conky startup script already exists in home directory."
fi
# Ensure conkystartup.sh is executable
chmod +x "$HOME/conkystartup.sh" || { echo "Failed to make conkystartup.sh executable."; exit 1; }
#create autostart entry
echo "Creating autostart entry for Conky..."
AUTOSTART_FILE="$HOME/.config/autostart/conky.desktop"
echo "[Desktop Entry]" > "$AUTOSTART_FILE"
echo "Type=Application" >> "$AUTOSTART_FILE"
echo "Exec=$HOME/conkystartup.sh" >> "$AUTOSTART_FILE"
echo "Hidden=false" >> "$AUTOSTART_FILE"
echo "NoDisplay=false" >> "$AUTOSTART_FILE"
echo "X-GNOME-Autostart-enabled=true" >> "$AUTOSTART_FILE"
echo "Name=Conky Startup" >> "$AUTOSTART_FILE"
echo "Comment=Start Conky at login" >> "$AUTOSTART_FILE"
echo "Autostart entry created at $AUTOSTART_FILE"

# Print completion message
echo "Conky setup completed successfully!"
# Print instructions for manual start
echo "You can start Conky manually by running: ~/conkystartup.sh"
# Print instructions for autostart
echo "To ensure Conky starts automatically on login, make sure the autostart entry is created in $HOME/.config/autostart/conky.desktop"
# Print instructions for configuration
echo "You can edit the Conky configuration files in $HOME/.config/conky/ to customize your setup."
# Print instructions for uninstalling
echo "To uninstall Conky, you can run: sudo apt-get remove --purge conky" # Adjust based on your package manager
# Print instructions for removing autostart entry
echo "To remove the autostart entry, delete the file: $HOME/.config/autostart/conky.desktop"
# Print instructions for removing configuration files
echo "To remove the Conky configuration files, delete the directory: $HOME/.config/conky/"
# Print instructions for running conkyset.sh again
echo "To run this setup script again, execute: $HOME/conkyset.sh"
# Print instructions for checking Conky status
echo "To check if Conky is running, you can use: pgrep conky"
# Print instructions for checking Conky logs
echo "To check Conky logs, you can look at the output in your terminal or check the log files if configured in your Conky setup."
# Print instructions for checking Conky configuration
echo "To check the Conky configuration, you can run: conky -c $HOME/.config/conky/conky.conf"
# Print instructions for checking Conky version
echo "To check the Conky version, you can run: conky --version"
echo  "Have fun! - Gyurus"
# wait for user hit any key before start conky
read -n 1 -s -r -p "Press any key to start Conky..."
echo
# Start Conky
$HOME/conkystartup.sh



#!/bin/bash
# linux 
# Ensure necessary folders exist
mkdir -p ~/.config/conky
mkdir -p ~/.config/autostart

# Check if Conky is installed
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

# Ensure pip is installed
if ! command -v pip &> /dev/null; then
    echo "pip is not installed. Installing pip..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y python3-pip || { echo "Failed to install pip."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu python-pip || { echo "Failed to install pip."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y python3-pip || { echo "Failed to install pip."; exit 1; }
    else
        echo "Package manager not supported. Please install pip manually."
        exit 1
    fi
else
    echo "pip is already installed."
fi

## Ensure wget is installed for downloading from the internet
if ! command -v wget &> /dev/null; then
    echo "wget is not installed. Installing wget..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y wget || { echo "Failed to install wget."; exit 1; }
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

# Download conky-system-set.tar.gz from Google Drive (public link)
FILE_ID="17Du4YmcwJjQ1AUxu-RsQtj_DaxVCI-ki"
DEST="$HOME/.config/conky/conky.config.tar.gz"
echo "Downloading conky.config..."
wget --no-check-certificate "https://drive.google.com/uc?export=download&id=$FILE_ID" -O "$DEST" || { echo "Failed to download conky.config."; exit 1; }
# unpacking zip file
/usr/bin/tar -xzf "$DEST" -C "$HOME/.config/conky" || { echo "Failed to extract conky.config."; exit 1; }
# Remove the downloaded tar.gz file
rm "$DEST" || { echo "Failed to remove the downloaded file."; exit 1; }
# move conkystartup.sh to ~
mv "$HOME/.config/conky/conkystartup.sh" "$HOME/" || { echo "Failed to move conkystartup.sh."; exit 1; }
# Make conkystartup.sh executable   
chmod +x "$HOME/conkystartup.sh" || { echo "Failed to make conkystartup.sh executable."; exit 1; }
# Ask if user wants to make an autostart entry and if yes create, and ask if user want to run conky now
read -p "Do you want to create an autostart entry for Conky? (y/n): " create_autostart      
if [[ "$create_autostart" =~ ^[Yy]$ ]]; then
    # Create autostart entry
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
else
    echo "No autostart entry created."
fi
# Prompt the user to decide whether to start Conky immediately after setup
read -p "Do you want to run Conky now? (y/n): " should_run_conky
if [[ "$should_run_conky" =~ ^[Yy]$ ]]; then
    echo "Running Conky..."
    conky || { echo "Failed to start Conky."; exit 1; }
else
    echo "Conky will not be started now."
fi
# Print completion message
echo "Conky setup completed successfully!"
# Print instructions for manual start
echo "You can start Conky manually by running: conky"
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

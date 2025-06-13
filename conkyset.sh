#!/bin/bash
# linux
# Start prechecks
echo "Starting prechecks for Conky setup..."

# Check if conkystartup.sh and remove-conkysettings.sh are present in this directory and then move them to the home directory
echo "Checking for required scripts in the current directory..."
if [ ! -f "conkystartup.sh" ] && [ ! -f "remove-conkysettings.sh" ]; then
    echo "Required scripts not found in the current directory. Please ensure conkystartup.sh and remove-conkysettings.sh are present."
    exit 1
else
    echo "Required scripts found in the current directory."
    # Move scripts to home directory
    mv conkystartup.sh "$HOME/" || { echo "Failed to move conkystartup.sh to home directory."; exit 1; }
    mv remove-conkysettings.sh "$HOME/" || { echo "Failed to move remove-conkysettings.sh to home directory."; exit 1; }
    echo "Scripts moved to home directory successfully."    
fi

# Check if conky.template.conf exists in this directory
if [ ! -f "conky.template.conf" ]; then
    echo "Conky template configuration file not found in the current directory. Please ensure conky.template.conf is present."
    exit 1
else
    echo "Conky template configuration file found in the current directory."
    # Create .config/conky directory if it doesn't exist
    mkdir -p "$HOME/.config/conky" || { echo "Failed to create .config/conky directory."; exit 1; }
    # Move conky.template.conf to .config/conky/conky.conf
    mv conky.template.conf "$HOME/.config/conky/conky.conf" || { echo "Failed to move conky.template.conf to .config/conky/conky.conf."; exit 1; }
    echo "Conky template configuration file moved to $HOME/.config/conky/conky.conf successfully."
fi
# Template copied
echo "Conky template configuration file copied successfully."
pause() {
    read -n 1 -s -r -p "Press any key to continue..."
    echo
}


# Ensure scripts are executable
chmod +x "$HOME/conkystartup.sh" || { echo "Failed to make conkystartup.sh executable."; exit 1; }
chmod +x "$HOME/remove-conkysettings.sh" || { echo "Failed to make remove-conkysettings.sh executable."; exit 1; }
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



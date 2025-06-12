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

# Ensure gdown is installed for downloading from Google Drive
if ! command -v gdown &> /dev/null; then
    echo "gdown is not installed. Installing gdown..."
    pip install --user gdown || { echo "Failed to install gdown."; exit 1; }
    export PATH="$HOME/.local/bin:$PATH"
else
    echo "gdown is already installed."
fi

# Download conky-system-set.tar.gz from Google Drive https://drive.google.com/file/d/17Du4YmcwJjQ1AUxu-RsQtj_DaxVCI-ki/view?usp=sharing
# Replace FILE_ID with the actual file ID from your shared link
FILE_ID="17Du4YmcwJjQ1AUxu-RsQtj_DaxVCI-ki"
DEST="$HOME/.config/conky/conky.config.tar.gz"
echo "Downloading conky.config..."
gdown "https://drive.google.com/uc?id=$FILE_ID" -O "$DEST"
# unpacking zip file
/usr/bin/tar -xzf "$DEST" -C "$HOME/.config/conky" || { echo "Failed to extract conky.config."; exit 1; }
# Remove the downloaded tar.gz file
rm "$DEST" || { echo "Failed to remove the downloaded file."; exit 1; }
# move conkystartup.sh to ~
mv "$HOME/.config/conky/conkystartup.sh" "$HOME/" || { echo "Failed to move conkystartup.sh."; exit 1; }
# Make conkystartup.sh executable   
chmod +x "$HOME/conkystartup.sh" || { echo "Failed to make conkystartup.sh executable."; exit 1; }

**conkyset.sh** is a simple Bash script to automate the installation and setup of Conky with a custom configuration on Linux systems.

## Features

- Installs Conky if not already present
- Installs required tools (e.g., `wget`, `pip`) — additional dependencies may be required depending on your Linux distribution; check the script for details.
- Downloads a pre-configured Conky setup archive from git
- Extracts and installs the configuration to `~/.config/conky`
- Sets up an autostart entry 
- runs Conky immediately after setup

## Usage

1. **Download the files**  
   Save them to your home directory or any folder.

2. **Make it executable**  
   ```bash
   chmod +x conkyset.sh
   ```

3. **Run the script**  
   ```bash
   ./conkyset.sh
   ```

4. **Follow the prompts**  
   The script will ask if you want to create an autostart entry and if you want to run Conky now.

## Requirements
- Linux (Debian/Ubuntu/Mint, Arch, Fedora, etc.)
  - For Debian/Ubuntu: `sudo apt-get install conky`
  - For Arch: `sudo pacman -S conky`
  - For Fedora: `sudo dnf install conky`
- Linux (Debian/Ubuntu, Arch, Fedora, etc.)
- Internet connection
- `sudo` privileges for installing packages

## Customization

## Troubleshooting

- Remove Conky:  
  Added new bash script

- Alternatively, host the configuration files on another platform (e.g., GitHub, Dropbox) for easier access.

## Uninstall
with the script 
remove-conkysettings.sh


**Have fun with your new Conky setup! - Gyurus**

**conkyset.sh** is a simple Bash script to automate the installation and setup of Conky with a custom configuration on Linux systems.

## Features

- Installs Conky if not already present
- Installs required tools (e.g., `wget`, `pip`) — additional dependencies may be required depending on your Linux distribution; check the script for details.
- Downloads a pre-configured Conky setup archive from Google Drive  
  *(Google Drive link:
  (https://drive.google.com/file/d/1W41kbTgQGQvkqbdRk8Gvw-0yoCqOwVKB/view?usp=drive_link))*
- Extracts and installs the configuration to `~/.config/conky`
- Sets up an autostart entry (optional)
- Optionally runs Conky immediately after setup

## Usage

1. **Download the script**  
   Save `conkyset.sh` to your home directory or any folder.

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
- Linux (Debian/Ubuntu, Arch, Fedora, etc.)
  - For Debian/Ubuntu: `sudo apt-get install conky`
  - For Arch: `sudo pacman -S conky`
  - For Fedora: `sudo dnf install conky`
- Linux (Debian/Ubuntu, Arch, Fedora, etc.)
- Internet connection
- `sudo` privileges for installing packages

## Customization

## Troubleshooting

- If the Google Drive download fails:
  1. Ensure the link is still valid by opening it in a browser.
  2. Check your internet connection and retry the script.
  3. For large files requiring confirmation, download the file manually:
     - Open the Google Drive link in your browser.
     - Click the "Download" button and confirm any warnings.
     - Save the file to your system.
  4. Once downloaded, manually extract the archive:
- Remove Conky:  
  - For Debian/Ubuntu:  
    ```bash
    sudo apt-get remove --purge conky
    ```
  - For Arch:  
    ```bash
    sudo pacman -Rns conky
    ```
  - For Fedora:  
    ```bash
    sudo dnf remove conky
    ```

- Alternatively, host the configuration files on another platform (e.g., GitHub, Dropbox) for easier access.

- If the Google Drive download fails, ensure the link is still valid and you have internet access.
- For Google Drive files that require confirmation (large files), manual download may be necessary.

## Uninstall

- Remove Conky:  
- Remove autostart entry:  
  Before running the command, verify that the file `~/.config/autostart/conky.desktop` exists:  
  ```bash
  [ -f ~/.config/autostart/conky.desktop ] && rm ~/.config/autostart/conky.desktop
  ```
- Remove configuration:  
  ```bash
  rm -rf ~/.config/conky/
  ```
- Remove autostart entry:  
  ```bash
  rm ~/.config/autostart/conky.desktop
  ```
---

**Have fun with your new Conky setup! - Gyurus**

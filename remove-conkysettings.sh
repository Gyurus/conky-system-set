# This script removes the conky settings file, conkystartup.sh 
# Ask user if want to uninstall Conky settings
#!/bin/bash
echo "Do you want to uninstall Conky settings? (y/n)"
read -r answer
if [[ "$answer" != "y" && "$answer" != "Y" ]]; then 
    echo "Uninstalling Conky settings..."
    echo ""
    rm -f "$HOME/.config/conky/conky.conf"
    echo "Conky settings uninstalled successfully."
    rm -f "$HOME/.config/autostart/conkystartup.sh"
    echo "Conky startup script removed successfully."
    echo ""
    exit 0
else
    echo "Uninstallation cancelled."
    echo ""
    echo "If you want to uninstall Conky settings, run this script again and answer 'y'."
    echo ""
    echo "If you want to keep the settings, just ignore this message."
    echo ""
    echo "To remove Conky settings manually, delete the following files:"
    echo "$HOME/.config/conky/conky.conf"
    echo "$HOME/.config/autostart/conkystartup.sh"
    echo ""
    echo "C
    exit 0

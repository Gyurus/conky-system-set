# Conky System Monitor v1.6

A comprehensive and visually clean Conky setup for monitoring your system in real time. Features auto-configuration, enhanced system monitoring, weather integration, and complete setup automation.onky System Monitor v1.5

A comprehensive and visually clean Conky setup for monitoring your system in real time. Features auto-configuration, enhanced system monitoring, and complete setup automation.

[https://postimg.cc/tZr0Hw2X](https://i.postimg.cc/Bb3J2GF1/Screenshot-2025-06-13-20-01-14.png)

---

## ✨ Features

- **Comprehensive System Monitoring**: CPU, RAM, storage, temperatures, and network
- **Enhanced Process Lists**: 5 top CPU and RAM consuming processes
- **Smart Temperature Detection**: CPU and system temperature with multiple sensor fallbacks
- **Network Auto-Detection**: Automatic detection of active network interface (WiFi/Ethernet)
- **Modern Design**: Transparent panel-style layout with `Roboto Mono` font
- **Battery Support**: Battery status and time remaining (when available)
- **Weather Integration**: Current weather information
- **Public IP Display**: Shows your current public IP address
- **Complete Automation**: Full setup, startup, and removal scripts
- **Non-Destructive**: Copy files instead of moving them
- **Cross-Platform**: Supports multiple package managers (apt, pacman, dnf)

---

## 📁 Files Overview

### `conky.template.conf`
> Template configuration file with placeholders that get replaced during setup.

**Includes:**
- Network interface placeholder (`@@IFACE@@`)
- Modern styling with semi-transparent background
- Roboto Mono font configuration

### `conkyset.sh` 
> **Main setup script** - Installs and configures the complete Conky system.

**Features:**
- ✅ Copies all required files (non-destructive)
- ✅ Installs Conky if not present
- ✅ Creates autostart entry
- ✅ Configures all components
- ✅ Supports multiple Linux distributions

**Usage:** 
```bash
./conkyset.sh
```

### `conkystartup.sh`
> **Startup script** - Configures network interface and launches Conky.

**Features:**
- ✅ Auto-detects active network interface
- ✅ Replaces template placeholders
- ✅ Generates final configuration
- ✅ Launches Conky with complete monitoring

**Usage:**
```bash
./conkystartup.sh
```

### `rm-conkyset.sh` 
> **Removal script** - Completely uninstalls Conky setup.

**Features:**
- ✅ Stops running Conky processes
- ✅ Removes all configuration files
- ✅ Removes autostart entries
- ✅ Cleans up copied scripts
- ✅ Provides manual removal instructions

**Usage:**
```bash
./rm-conkyset.sh
```

---

## 🚀 Quick Installation

1. **Make scripts executable:**
   ```bash
   chmod +x conkyset.sh conkystartup.sh rm-conkyset.sh
   ```

2. **Run the setup:**
   ```bash
   ./conkyset.sh
   ```

3. **Conky will start automatically!** 🎉

---

## 📊 System Information Displayed

- **Host Information**: Hostname, uptime, kernel version
- **Network**: WiFi SSID, signal strength, interface auto-detection
- **Temperatures**: CPU average temperature and system temperature
- **CPU/RAM**: Usage percentages with progress bars and graphs
- **Storage**: Root and home partition usage with bars
- **Disk I/O**: Real-time read/write speeds with graphs (NVMe optimized)
- **Top Processes**: 5 highest CPU and RAM consuming processes
- **Battery**: Status, time remaining, and charge level (when available)
- **External Data**: Weather information and public IP address
- **Time/Date**: Formatted date and time display

---

## 🔧 System Requirements

- **Conky**: v1.10 or newer (auto-installed)
- **Fonts**: Roboto Mono (recommended: `sudo apt install fonts-roboto`)
- **Sensors**: lm-sensors for temperature monitoring
- **Network Tools**: iw, nmcli for network detection
- **Compositor**: Optional for true transparency (e.g., picom)
- **Operating System**: Linux (tested on various distributions)

---

## 🛠️ Management Commands

### Check if Conky is running:
```bash
pgrep conky
```

### Restart Conky:
```bash
pkill conky && ~/conkystartup.sh
```

### Remove everything:
```bash
~/rm-conkyset.sh
```

### Reinstall:
```bash
./conkyset.sh
```

---

## 📋 File Locations

After installation, files are located at:
- **Configuration**: `~/.config/conky/conky.conf`
- **Interface Cache**: `~/.config/conky/.conky_iface`
- **Autostart Entry**: `~/.config/autostart/conky.desktop`
- **Startup Script**: `~/conkystartup.sh`
- **Removal Script**: `~/rm-conkyset.sh`

---

## 🗒️ What's New in v1.6

- **🌍 Enhanced Weather Location Setup**: Auto-detection with smart fallbacks and improved user prompts
- **📍 Improved Location Validation**: 2 full manual attempts before fallback to detected location
- **🌦️ Advanced Weather Reporting**: Comprehensive weather data with current conditions, forecasts, and sun times
- **🛡️ Better Error Handling**: Robust syntax error fixes and improved Conky configuration parsing
- **⚙️ Hardware Detection**: Enhanced GPU, thermal sensor, and hardware monitoring capabilities
- **🔧 Setup Script Improvements**: Better command-line options (--no-gpu, --nosensor, --auto-location)
- **💻 Brightness Monitoring**: Dynamic backlight detection across different hardware interfaces
- **📦 Dependency Management**: Smarter package installation and hardware-specific optimizations

---

## 🗒️ Previous Versions

### v1.5
- Added non-interactive `-y/--yes` flag to `conkyset.sh` for auto-default mode
- Improved monitor detection: use numeric `xinerama_head` index for robust positioning
- Enhanced process killing with `pkill -x` and safe fallback to avoid miskills
- Updated removal script to continue cleanup even if Conky processes do not terminate

---

## 📌 Notes

- **Distribution Support**: Supports Ubuntu/Debian (apt), Arch (pacman), and Fedora (dnf)
- **Non-Destructive**: Original files remain in project directory
- **Reusable**: Can be run multiple times safely
- **Temperature Monitoring**: Includes fallbacks for various sensor types
- **Network Flexibility**: Works with both wired and wireless interfaces
- **Auto-Start**: Configures automatic startup on login

---

## 🧑‍💻 License

MIT License — free for personal and commercial use. Attribution appreciated but not required.

**Created by Gyurus** - Have fun! 🎉





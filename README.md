# Conky System Monitor v1.8.4 (Multi-Monitor Support)

A comprehensive and visually clean Conky setup for monitoring your system in real time. Features auto-configuration, enhanced system monitoring, weather integration, **multi-monitor support with intelligent positioning**, complete setup automation, and **one-command online installation**.

[https://postimg.cc/tZr0Hw2X](https://i.postimg.cc/Bb3J2GF1/Screenshot-2025-06-13-20-01-14.png)

---

## 🚀 Quick Installation

### Online Installation (Recommended)

Install directly from GitHub with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

Or using wget:
```bash
wget -qO- https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/Gyurus/conky-system-set.git
cd conky-system-set
./conkyset.sh
```

For detailed online installation options, see [ONLINE_INSTALL.md](ONLINE_INSTALL.md)

---

## ✨ Features

- **🌐 One-Command Installation**: Install directly from GitHub
- **Comprehensive System Monitoring**: CPU, RAM, storage, temperatures, and network
- **🖥️ Multi-Monitor Support**: Intelligent detection and positioning across multiple displays
- **📍 Smart Window Positioning**: Auto-calculated positioning based on monitor resolution
- **🎯 Flexible Placement Options**: Top/bottom, left/right, center positioning on any monitor
- **Enhanced Process Lists**: 5 top CPU and RAM consuming processes
- **Smart Temperature Detection**: CPU and system temperature with multiple sensor fallbacks
- **Network Auto-Detection**: Automatic detection of active network interface (WiFi/Ethernet)
- **Modern Design**: Transparent panel-style layout with `Roboto Mono` font
- **Battery Support**: Battery status and time remaining (when available)
- **Weather Integration**: Current weather information with auto-location detection
- **Public IP Display**: Shows your current public IP address
- **🔄 Automatic Updates**: Built-in update checking and management
- **Complete Automation**: Full setup, startup, and removal scripts
- **Non-Destructive**: Copy files instead of moving them
- **Cross-Platform**: Supports multiple package managers (apt, pacman, dnf)

---

## 📁 Files Overview

### `install-online.sh` ✨ NEW
> **Online installer** - Downloads and sets up Conky System Set from GitHub.

**Features:**
- ✅ One-command installation
- ✅ Checks prerequisites automatically
- ✅ Downloads all necessary files
- ✅ Option for full or minimal installation
- ✅ Interactive setup with sensible defaults
- ✅ Can run setup immediately after install

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
- 🖥️ **Multi-monitor support with intelligent positioning**
- 📍 **Resolution-aware window placement**
- 🔄 **Automatic update checking**

**Usage:** 
```bash
# Basic interactive setup
./conkyset.sh

# Quick setup with options
./conkyset.sh --yes --position top_left --auto-location
```

**Command-line Options:**
- `-y, --yes` - Non-interactive mode (auto-confirm prompts)
- `--position` - Window position: top_right, top_left, bottom_right, bottom_left, center
- `--monitor` - Force specific monitor by name (e.g., DP-1, HDMI-A-1)
- `--auto-location` - Auto-detect weather location
- `--no-gpu` - Skip GPU detection
- `--nosensor` - Skip thermal sensor checks
- `--check-updates` - Check for updates and prompt user
- `--force-update-check` - Force update check regardless of interval
- `--skip-update-check` - Skip automatic update check

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

## 🖥️ Multi-Monitor Support

### Automatic Multi-Monitor Detection

The system automatically detects all connected monitors and provides intelligent positioning options:

```bash
# Basic setup with interactive monitor selection
./conkyset.sh

# Non-interactive setup (uses primary monitor)
./conkyset.sh --yes

# Specify window position
./conkyset.sh --position top_left
./conkyset.sh --position bottom_right
./conkyset.sh --position center
```

### Available Position Options

| Position | Description |
|----------|-------------|
| `top_right` | Top-right corner (default) |
| `top_left` | Top-left corner |
| `bottom_right` | Bottom-right corner |
| `bottom_left` | Bottom-left corner |
| `center` | Center of the screen |

### Advanced Multi-Monitor Options

```bash
# Force specific monitor by name
./conkyset.sh --monitor DP-1
./conkyset.sh --monitor HDMI-A-1

# Combine options for complex setups
./conkyset.sh --yes --position bottom_left --monitor DP-2

# Auto-setup with specific positioning
./conkyset.sh --yes --auto-location --position center
```

### Monitor Information Display

During setup, the system will show detailed monitor information:
```
🖥️ Detected 2 monitor(s):

1. DP-1 (Primary)
   Resolution: 2560x1440
   Position: +0+0
   Size: 2560×1440 pixels

2. HDMI-A-1
   Resolution: 1920x1080
   Position: +2560+0
   Size: 1920×1080 pixels
```

### How Resolution-Based Positioning Works

- **Automatic Calculations**: Window position is calculated based on monitor resolution
- **Safe Margins**: 30px margin from edges to prevent window clipping
- **Multi-Monitor Aware**: Handles monitor offsets in extended desktop setups
- **Resolution Adaptive**: Adjusts positioning for different monitor sizes

---

## 🔄 Automatic Updates

The system includes intelligent update checking to keep your Conky setup current.

### Update Check Features

- **Automatic Checking**: Checks for updates every 24 hours
- **Version Skipping**: Option to skip specific versions you don't want
- **Smart Prompting**: Only prompts when updates are actually available
- **Git Integration**: Automatic updates if installed via git
- **Manual Override**: Force checks or disable automatic checking

### Update Commands

```bash
# Check for updates manually
./conkyset.sh --check-updates

# Force update check (ignore 24h interval)
./conkyset.sh --force-update-check

# Skip automatic update check during setup
./conkyset.sh --skip-update-check --yes

# Normal setup with automatic update check
./conkyset.sh
```

### Update Process Flow

When an update is detected, you'll see:

```
🎉 New version available: v1.8.0

🔄 Update Options:
==================

1. Update now (recommended)
2. Skip this version
3. Remind me later
4. Show release notes

❓ What would you like to do? [1]:
```

### Update Behaviors

| Option | Behavior |
|--------|----------|
| **Update now** | Downloads and installs the latest version |
| **Skip this version** | Never prompts for this specific version again |
| **Remind me later** | Asks again in 24 hours |
| **Show release notes** | Displays changelog and returns to menu |

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

## � Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Complete version history with detailed changes, fixes, and migration guides
- **[ONLINE_INSTALL.md](ONLINE_INSTALL.md)** - Comprehensive online installation guide with troubleshooting

---

## �📌 Notes

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





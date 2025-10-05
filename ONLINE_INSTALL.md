# Online Installation Guide

## Quick Installation

### One-Line Installation Command

Users can install Conky System Set directly from GitHub with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

### Safe Installation (Recommended)

For users who want to inspect the script before running:

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh -o install-conky.sh

# Review the script
less install-conky.sh

# Make it executable
chmod +x install-conky.sh

# Run the installer
./install-conky.sh
```

## What the Online Installer Does

The `install-online.sh` script:

1. **Checks Prerequisites**
   - Verifies `curl` or `wget` is available
   - Checks for `git` installation
   - Optionally checks for `jq` (for better GitHub API handling)

2. **Creates Directory Structure**
   - Creates `~/.conky-system-set/` directory
   - Sets up `modules/` subdirectory

3. **Downloads Essential Files**
   - Main setup script (`conkyset.sh`)
   - Startup script (`conkystartup.sh`)
   - Removal script (`rm-conkyset.sh`)
   - Template configuration (`conky.template.conf`)
   - All module files (`modules/*.sh`)
   - README and documentation

4. **Optional Full Download**
   - Offers to download ALL repository files
   - Includes test scripts, documentation, etc.

5. **Sets Up Access**
   - Option 1: Copy scripts to home directory (default)
   - Option 2: Create symlinks to home directory
   - Option 3: Keep only in install directory

6. **Makes Scripts Executable**
   - Sets proper permissions on all `.sh` files

7. **Offers Immediate Setup**
   - Can run `conkyset.sh` immediately after installation

## Installation Options

### Default Installation
```bash
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

### Development Branch (Multi-Monitor Features)
```bash
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/feature/multi-monitor-support/install-online.sh | bash
```

### Install to Custom Directory
```bash
# Download installer first
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh -o install-conky.sh

# Edit the INSTALL_DIR variable
nano install-conky.sh

# Run installer
bash install-conky.sh
```

## Requirements

### Minimum Requirements
- `curl` or `wget`
- `git`
- Internet connection

### Recommended
- `jq` - For better GitHub API parsing
- `bash` 4.0 or later

### Installation of Requirements

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl git jq
```

**Fedora/RHEL:**
```bash
sudo dnf install curl git jq
```

**Arch Linux:**
```bash
sudo pacman -S curl git jq
```

## Features of Online Installer

### Safety Features
- ✅ Checks for existing installations (prompts before overwriting)
- ✅ Validates prerequisites before downloading
- ✅ Graceful Ctrl+C handling
- ✅ Clear error messages and status indicators
- ✅ Option to review what will be downloaded

### User-Friendly
- 🎨 Colored output for better readability
- 📊 Progress indicators for downloads
- 💬 Interactive prompts with sensible defaults
- 📝 Comprehensive installation summary
- 🚀 Option to run setup immediately

### Flexible
- 📂 Choose how scripts are accessed (copy/symlink/directory)
- 🌐 Download only essentials or complete repository
- 🔧 Configurable installation directory
- 🌿 Support for different branches (main/development)

## Post-Installation

After installation completes, you can:

### Run Setup
```bash
~/conkyset.sh
```

### View Help
```bash
~/conkyset.sh --help
```

### Non-Interactive Setup
```bash
~/conkyset.sh -y
```

### Check Installation
```bash
ls -la ~/.conky-system-set/
```

### Update Later
```bash
# The setup script includes automatic update checking
~/conkyset.sh --check-updates
```

### Remove Installation
```bash
~/rm-conkyset.sh
```

## Troubleshooting

### Download Fails
If downloads fail:
1. Check internet connection
2. Verify GitHub is accessible
3. Try using `wget` instead of `curl` (or vice versa)
4. Check if repository URL is correct

### Permission Denied
```bash
chmod +x ~/conkyset.sh ~/conkystartup.sh ~/rm-conkyset.sh
```

### Missing Dependencies
Install required packages:
```bash
# Ubuntu/Debian
sudo apt install curl git jq conky-all

# Fedora
sudo dnf install curl git jq conky

# Arch
sudo pacman -S curl git jq conky
```

### Clean Reinstall
```bash
# Remove existing installation
rm -rf ~/.conky-system-set/
rm -f ~/conkyset.sh ~/conkystartup.sh ~/rm-conkyset.sh

# Run installer again
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

## Security Considerations

### Verify Script Before Running
Always review scripts before piping to bash:
```bash
# View the installer script
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | less

# Or download and inspect
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh -o install-conky.sh
cat install-conky.sh
```

### What the Installer Does NOT Do
- ❌ Does not require sudo/root access
- ❌ Does not modify system files
- ❌ Does not install system packages automatically
- ❌ Does not collect or transmit user data
- ❌ Does not modify existing Conky configurations (backs up first)

### Safe Installation Practices
1. Review the installer script source code
2. Download and inspect before running
3. Run without sudo (installs to user directory only)
4. Check GitHub repository reputation and stars
5. Review installation directory before confirming

## Comparison: Online vs Manual Installation

### Online Installation
**Pros:**
- ✅ One command installation
- ✅ Always gets latest version
- ✅ Automatic file selection
- ✅ No need to clone repository
- ✅ Minimal disk space

**Cons:**
- ❌ Requires internet during install
- ❌ Less control over what's downloaded
- ❌ Can't easily modify before installing

### Manual Git Clone
**Pros:**
- ✅ Full repository history
- ✅ Easy to contribute/modify
- ✅ Can switch branches easily
- ✅ Offline access after clone

**Cons:**
- ❌ More steps required
- ❌ Larger disk space usage
- ❌ Must manage updates manually

## Example Installation Session

```
$ curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash

╔══════════════════════════════════════════════════════════════╗
║        Conky System Set - Online Installer v1.8             ║
╚══════════════════════════════════════════════════════════════╝

This script will download and install Conky System Set from GitHub.
Repository: https://github.com/Gyurus/conky-system-set
Branch: main
Install location: /home/user/.conky-system-set

Continue with installation? (Y/n): y

▶ Checking prerequisites...
✅ All prerequisites satisfied

▶ Creating directory structure...
✅ Directory structure created

▶ Downloading essential files from GitHub...
   Downloading: conkyset.sh ... ✓
   Downloading: conkystartup.sh ... ✓
   Downloading: rm-conkyset.sh ... ✓
   [...]
ℹ️  Downloaded: 11 files, Failed: 0 files

▶ Would you like to download ALL files including tests and docs?
This includes test scripts, documentation, etc. (y/N): n
ℹ️  Skipping optional files

▶ Setting executable permissions...
✅ Permissions set

▶ Setting up quick access...
How would you like to access the scripts?
  1. Copy scripts to home directory (default)
  2. Create symlinks in home directory
  3. Skip (access from install directory only)
Choice [1]: 1
✅ Scripts copied to /home/user

╔══════════════════════════════════════════════════════════════╗
║              INSTALLATION COMPLETE!                          ║
╚══════════════════════════════════════════════════════════════╝

✅ Conky System Set v1.8 has been installed!

📁 Installation directory: /home/user/.conky-system-set

🚀 NEXT STEPS:
═════════════

1. Run the setup script:
   ~/conkyset.sh

2. For help and options:
   ~/conkyset.sh --help
[...]

Would you like to run the setup now? (y/N): y

▶ Starting Conky setup...

[Setup continues...]
```

## Support

For issues with the online installer:
1. Check this documentation
2. Review troubleshooting section
3. Report issues: https://github.com/Gyurus/conky-system-set/issues
4. Include installer output and error messages

## Version History

### v1.8 (Current)
- ✨ New online installer
- 🖥️ Multi-monitor support improvements
- 🔄 Enhanced update system
- 🎨 Improved user experience
- 🛡️ Better error handling

### v1.7-dev
- 🔧 Multi-monitor detection
- 📊 Enhanced positioning options
- 🔍 Smart monitor selection

---

**Happy Conky-ing! 🚀**

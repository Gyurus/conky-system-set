# Conky System Set - AI Agent Instructions

## Project Overview
Conky System Set is a comprehensive Bash-based Linux system monitor that provides auto-configuration, multi-monitor support, and weather integration. The system uses a **template-and-placeholder architecture** where `conky.template.conf` contains placeholders (e.g., `@@IFACE@@`, `@@GPU_TEMP_COMMAND@@`) that are replaced at runtime with detected hardware values.

**Current Version:** Tracked in `VERSION` file

## Critical Architecture

### Template-Based Configuration System
- **Template file:** `conky.template.conf` contains static placeholders
- **Runtime replacement:** `conkystartup.sh` detects hardware and replaces placeholders using `sed -i`
- **Final config:** Generated to `~/.config/conky/conky.conf`
- **Key placeholders:** `@@IFACE@@` (network), `@@GPU_TEMP_COMMAND@@` (GPU), `@@ALIGNMENT@@`, `@@GAP_X@@`, `@@GAP_Y@@`, `@@MONITOR@@`

### Modular Detection System
All hardware detection logic lives in `modules/` and is sourced by main scripts:
- `modules/iface.sh` - Network interface detection (prefers Ethernet, falls back to Wi-Fi)
- `modules/gpu.sh` - GPU detection (NVIDIA/AMD/Intel) with vendor-specific tools
- `modules/monitor.sh` - Multi-monitor detection using xrandr, stores arrays of monitor names/resolutions/positions
- `modules/update.sh` - Update checking with GitHub API, auto-update capability
- `modules/weather.sh` - Weather location detection and integration
- `modules/process.sh` - Process monitoring utilities

**Module usage pattern:** Scripts source modules using `source "$(dirname "$0")/modules/<name>.sh"` then call exported functions.

### Installation Workflows

#### Three Installation Paths:
1. **Online install:** `curl | bash` → downloads files to `~/.conky-system-set` → optionally runs setup
2. **Manual install:** Clone repo → run `./conkyset.sh` directly
3. **Development:** Run from repo directory (LOCAL_MODE in install-online.sh)

#### File Installation Locations:
- Installation dir: `~/.conky-system-set/` (scripts, modules, templates)
- Config dir: `~/.config/conky/` (final conky.conf, cached interface name)
- Autostart: `~/.config/autostart/conky.desktop`
- Update tracking: `~/.conky-system-set-*` files in home directory

### Script Lifecycle

**Setup Flow (conkyset.sh):**
1. Parse CLI flags (--yes, --position, --monitor, --no-gpu, etc.)
2. Source all modules from `modules/`
3. Check/install dependencies (conky, sensors, curl/wget)
4. Detect hardware (GPU, monitors, network) using module functions
5. Prompt for configuration (monitor selection, position, weather)
6. Calculate window positioning based on monitor resolution and chosen corner
7. Copy template → `~/.config/conky/conky.conf` with position placeholders filled
8. Create autostart entry calling `conkystartup.sh`

**Startup Flow (conkystartup.sh):**
1. Source `modules/update.sh` and check for auto-updates
2. Detect active network interface at boot time
3. Replace `@@IFACE@@` in config with detected interface
4. Detect GPU and replace `@@GPU_TEMP_COMMAND@@` with vendor-specific command
5. Launch Conky in background

## Development Conventions

### Bash Style Patterns
- **Shebang:** Always `#!/bin/bash` (not sh, requires bash features)
- **Error handling:** Main scripts use early exits, modules return functions
- **Variable naming:** UPPERCASE for globals/constants, lowercase for locals
- **Array usage:** Declare arrays with `declare -a` (indexed) or `declare -A` (associative)
- **Command substitution:** Use `$()` not backticks
- **Testing existence:** `command -v <tool>` for commands, `[ -f path ]` for files

### Critical sed Pattern
When updating placeholders in config files, **always escape special characters** in replacement strings:
```bash
escaped_gpu_command=$(printf '%s\n' "$GPU_COMMAND" | sed -e 's/[&\\|]/\\&/g')
sed -i "s|@@PLACEHOLDER@@|$escaped_gpu_command|" "$config_file"
```
Use `|` as sed delimiter (not `/`) because paths contain slashes.

### Multi-Monitor Positioning Math
Positioning logic in `modules/monitor.sh` calculates gap_x/gap_y based on:
- Monitor resolution (width/height from xrandr)
- Monitor position offset (multi-monitor X offset)
- Chosen corner (top_right, top_left, bottom_right, bottom_left, center)
- Fixed widget width: 320px
- Example: `gap_x = monitor_width - 320 - 10` for top_right

### Version Management
- Version stored as single line in `VERSION` file (e.g., "1.9.3\n")
- Update via `./update_version.sh <version>` which updates VERSION + README title
- **Never hardcode version numbers** in scripts (read from VERSION file)
- GitHub releases use `v` prefix (v1.9.3), internal version has no prefix (1.9.3)

## Testing & Debugging

### Manual Testing Commands
```bash
# Test setup with specific options
./conkyset.sh --yes --position top_left --monitor DP-1 --skip-update-check

# Test startup script (requires config already exists)
./conkystartup.sh

# Test module functions directly
source modules/iface.sh && get_iface

# Dry-run removal (see what would be deleted)
./rm-conkyset.sh --dry-run

# Test online installer in local mode (from repo dir)
./install-online.sh
```

### Hardware Detection Debugging
- GPU detection: Check `lspci | grep -i vga` and vendor tools (nvidia-smi, radeontop)
- Network: Use `ip route get 1.1.1.1` to find default interface
- Monitors: Run `xrandr --query` to see available outputs
- Sensors: Check `sensors` output for thermal zones

## Common Tasks

### Adding a New Placeholder
1. Add `@@NEW_PLACEHOLDER@@` to `conky.template.conf`
2. Create detection logic in appropriate module or startup script
3. Use sed replacement pattern: `sed -i "s|@@NEW_PLACEHOLDER@@|$detected_value|g" "$config_file"`
4. Ensure replacement happens before Conky launch

### Adding CLI Option to conkyset.sh
1. Add to `show_help()` function documentation
2. Add flag variable at top (default value)
3. Add case in argument parser (lines 30-100)
4. Use flag in main logic

### Updating Dependencies
Dependency checking happens in `conkyset.sh` around line 200-400. Add package detection:
```bash
if ! command -v <tool> >/dev/null 2>&1; then
    # Detect package manager and install
fi
```

## External Dependencies
- **Required:** conky, bash, xrandr (for multi-monitor)
- **Optional:** sensors/lm-sensors (temps), nvidia-smi/radeontop (GPU), curl/wget (updates/weather)
- **Package managers supported:** apt (Debian/Ubuntu), pacman (Arch), dnf (Fedora/RHEL)

## File Ownership & Workflow
- Never move user files, always **copy** (non-destructive)
- Previous installation cleanup via `check-existing-conky.sh` detection
- Users can preserve `~/.conky` config when uninstalling
- Autostart creation doesn't require sudo (user autostart directory)

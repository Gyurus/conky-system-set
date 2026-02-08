# Dynamic Monitor Detection & Adjustment for Conky

## Overview

Conky System Set now includes dynamic monitor detection and automatic positioning adjustment. When you connect or disconnect a monitor, Conky will automatically:

1. **Detect** the monitor layout change
2. **Recalculate** optimal positioning based on the new configuration
3. **Reload** Conky with adjusted settings

This eliminates the need to manually reconfigure Conky when your display setup changes.

## How It Works

### Monitor Detection System

The system uses three key components:

#### 1. **Monitor Snapshot** (`modules/monitor-watch.sh`)
Creates a hash (MD5) of the current monitor configuration to detect changes:
- Snapshot stored in: `~/.config/conky/.monitor_snapshot`
- Checked on every Conky startup
- Automatically updates when changes are detected

#### 2. **Position Preference Storage**
Your chosen position preference (top_right, top_left, bottom_right, bottom_left, center) is saved:
- Stored in: `~/.config/conky/.monitor_preference`
- Set during initial `conkyset.sh` configuration
- Reapplied when monitors change

#### 3. **Monitor State Tracking**
Logs connected monitors for detailed change detection:
- Stored in: `~/.config/conky/.monitor_state`
- Logs which monitors were added/removed
- Used for informational purposes in logs

### Automatic Adjustment Workflow

```
Conky Startup (conkystartup.sh)
    ↓
Load Monitor-Watch Module
    ↓
Check Monitor Layout
    ├─ No Change → Continue normal startup
    └─ Change Detected
        ↓
        Load Saved Position Preference
        ↓
        Detect Current Monitors
        ↓
        Recalculate Positioning
        ├─ For Primary Monitor (if available)
        └─ With Saved Position Preference
        ↓
        Update conky.conf
        ↓
        Reload Conky Process
        ↓
        Log Changes
```

## Configuration

### Initial Setup

When you run `conkyset.sh`, it automatically:
1. Detects all connected monitors
2. Asks you to select a monitor
3. Asks you to choose a position (top_right, top_left, etc.)
4. **Saves this preference** for future use

```bash
./conkyset.sh
```

### Command-Line Options

Control monitor detection during setup:

```bash
# Force a specific monitor by name
./conkyset.sh --monitor DP-1

# Choose position preference
./conkyset.sh --position top_left

# Non-interactive mode (uses primary monitor, defaults to top_right)
./conkyset.sh --yes
```

## Monitoring Monitor Changes

### Check Monitor Status

View current and saved monitor information:

```bash
# See current connected monitors
xrandr --query | grep connected

# View saved position preference
cat ~/.config/conky/.monitor_preference

# Check monitor snapshot hash
cat ~/.config/conky/.monitor_snapshot
```

### View Detailed Logs

Conky logs all startup and monitor change operations:

```bash
# View boot/startup logs
tail -f ~/.config/conky/startup.log

# Watch for monitor changes in real-time
watch -n 5 'tail -20 ~/.config/conky/startup.log | grep "Monitor\|GPU\|interface"'
```

## Use Cases

### Multi-Monitor Laptop Setup

**Scenario:** Using laptop with docking station
- At home: Connected to monitor (Monitor configuration A)
- At office: Connected to different monitor (Monitor configuration B)
- Working: Monitor disconnected (Using laptop screen)

**How it works:**
- First boot with external monitor → Position calculated for external display
- Disconnect monitor → Conky automatically adjusts to laptop screen
- Connect to different monitor → Positioning recalculates automatically

### USB Display Adapter

**Scenario:** Using USB-C to HDMI for presentations
- Plug in projector → Conky recalculates position for projector
- Unplug projector → Conky reverts to laptop display positioning

### Multiple External Monitors

**Scenario:** Changing between different multi-monitor setups
- 2-monitor setup → 3-monitor setup
- Conky automatically detects and adjusts positioning on primary monitor

## Environment Files Set During Setup

| File | Purpose | Format |
|------|---------|--------|
| `~/.config/conky/.monitor_preference` | Selected position preference | `top_right`, `top_left`, `bottom_right`, `bottom_left`, or `center` |
| `~/.config/conky/.monitor_snapshot` | Hash of monitor configuration | MD5 hash string |
| `~/.config/conky/.monitor_state` | List of connected monitors | One monitor name per line |
| `~/.config/conky/conky.conf` | Final Conky configuration | Generated from template |

## Troubleshooting

### Monitor Changes Not Detected

**Problem:** Plugged in new monitor but Conky didn't adjust

**Solutions:**

1. **Check if xrandr is installed:**
   ```bash
   command -v xrandr && echo "xrandr found" || echo "xrandr not found"
   ```

2. **Manually trigger detection:**
   ```bash
   # Kill Conky
   pkill conky
   
   # Run startup script (which detects changes)
   ~/.conky-system-set/conkystartup.sh
   ```

3. **Check logs for errors:**
   ```bash
   tail -50 ~/.config/conky/startup.log | grep -i error
   ```

### Conky Not Reloading After Monitor Change

**Problem:** Monitor configuration changed but Conky still uses old positioning

**Solution - Restart Conky:**

```bash
# Manual restart
pkill conky
sleep 2
conky -c ~/.config/conky/conky.conf &

# Or use the monitor-watch reload function
source ~/.conky-system-set/modules/monitor-watch.sh
reload_conky
```

### Wrong Monitor Selection After Change

**Problem:** Conky appears on wrong display after monitor change

**Reset Position Preference:**

```bash
# Re-run setup with monitor selection
./conkyset.sh

# Or manually set preference
echo "top_left" > ~/.config/conky/.monitor_preference

# Force detection refresh
rm ~/.config/conky/.monitor_snapshot
```

## Advanced Usage

### Manual Monitor Detection

Force a complete monitor scan and repositioning:

```bash
# Source the monitor-watch module
source ~/.conky-system-set/modules/monitor-watch.sh

# Manually trigger change handling
handle_monitor_changes \
    ~/.config/conky/conky.conf \
    ~/.conky-system-set \
    "top_right"
```

### Check for Monitor State Changes

See exactly which monitors were added/removed:

```bash
source ~/.conky-system-set/modules/monitor-watch.sh
get_monitor_changes
```

### Recalculate Without Reload

Update config without restarting Conky:

```bash
source ~/.conky-system-set/modules/monitor-watch.sh
recalculate_monitor_position \
    ~/.config/conky/conky.conf \
    ~/.conky-system-set \
    "top_right"
```

## How Position Preferences Work

### Supported Positions

| Position | Description | Best Used For |
|----------|-------------|---------------|
| `top_right` | Upper right corner (default) | Corner positioning |
| `top_left` | Upper left corner | Corner positioning |
| `bottom_right` | Lower right corner | Taskbar avoidance |
| `bottom_left` | Lower left corner | Taskbar avoidance |
| `center` | Centered on monitor | Drawing attention |

### Position Calculation

For single monitors, gaps are simple offsets from the edge.

For multi-monitor setups:
- Selected monitor position is offset by monitor's X/Y position
- Single pixel-space coordinate system handles wrapping
- Prevents Conky appearing off-screen with unusual configurations

## System Requirements

- **Required:** `xrandr` for monitor detection
- **Optional:** `nmcli` for fallback network interface detection
- **Optional:** `sensors`, `nvidia-smi` for GPU temperature display

## Performance Notes

- Monitor detection is **non-blocking** at startup
- Snapshot hashing is **fast** (MD5 of monitor names/resolutions)
- Conky reload is **instantaneous** (pkill + restart)
- Negligible CPU/memory overhead for monitoring functionality

## Related Documentation

- [README.md](/README.md) - Main project documentation
- [CHANGELOG.md](../CHANGELOG.md) - Version history and updates
- `modules/monitor.sh` - Core monitor detection logic
- `modules/monitor-watch.sh` - Dynamic change detection

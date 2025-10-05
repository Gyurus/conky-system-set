# Online Installer - LOCAL_MODE Implementation

## Overview
The online installer (`install-online.sh`) now supports LOCAL_MODE for testing before pushing to GitHub.

## Problem Solved
**Issue**: When testing the installer before pushing to GitHub, it would fail with 404 errors because files don't exist on GitHub yet.

**Solution**: Automatic LOCAL_MODE detection that copies files from the local repository instead of downloading from GitHub.

## How It Works

### 1. Automatic Detection
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_MODE=false
if [ -f "$SCRIPT_DIR/conkyset.sh" ] && [ -f "$SCRIPT_DIR/conky.template.conf" ]; then
    LOCAL_MODE=true
fi
```

The installer automatically detects if it's running from a repository directory by checking for key files.

### 2. Visual Feedback
When LOCAL_MODE is enabled, the installer displays:
```
╔══════════════════════════════════════════════════════════════╗
║        Conky System Set - Online Installer v1.8             ║
╚══════════════════════════════════════════════════════════════╝

ℹ️  🔧 LOCAL MODE: Running from repository directory
ℹ️  Files will be copied locally (for testing)
```

### 3. Smart File Handling
The `download_file()` function now:
1. **Checks LOCAL_MODE first**: If enabled, tries to copy from local directory
2. **Handles subdirectories**: Properly resolves paths like `modules/update.sh`
3. **Falls back to online**: If local file not found, tries GitHub download
4. **Better error messages**: Distinguishes between 404 (file not on GitHub) and other errors

```bash
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    # If in local mode, copy from local directory
    if [ "$LOCAL_MODE" = true ]; then
        local relative_path="${url##*/}"
        local local_file="$SCRIPT_DIR/$relative_path"
        
        # Handle subdirectories (e.g., modules/update.sh)
        if [[ "$url" == *"/modules/"* ]]; then
            relative_path="modules/${url##*/modules/}"
            local_file="$SCRIPT_DIR/$relative_path"
        fi
        
        if [ -f "$local_file" ]; then
            cp "$local_file" "$output" 2>/dev/null && return 0
        fi
        
        print_warning "Local file not found: $local_file, trying online..."
    fi
    
    # Try online download
    if command_exists curl; then
        if curl -fsSL "$url" -o "$output" 2>/dev/null; then
            return 0
        else
            local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
            if [ "$http_code" = "404" ]; then
                print_error "File not found on GitHub (404): $description"
                print_info "The file may not be pushed to GitHub yet"
                return 1
            fi
        fi
    fi
    # ... wget fallback
}
```

## Testing Workflow

### For Developers (Before GitHub Push)
1. Make changes to installer or other files
2. Run `./install-online.sh` from repository directory
3. LOCAL_MODE automatically activates
4. Files are copied from local directory
5. Test installation process
6. If successful, push to GitHub

### For End Users (After GitHub Push)
1. Download installer: `curl -O https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh`
2. Run: `bash install-online.sh`
3. LOCAL_MODE stays false
4. Files downloaded from GitHub
5. Normal online installation

## Benefits

✅ **No more 404 errors during development testing**
✅ **Seamless switching between local and online mode**
✅ **Clear visual feedback about mode**
✅ **Better error messages with context**
✅ **Automatic detection - no manual configuration needed**
✅ **Preserves full online functionality**

## File Structure Requirements

For LOCAL_MODE to activate, the script must be run from a directory containing:
- `conkyset.sh` (main setup script)
- `conky.template.conf` (configuration template)

This ensures it only activates in a valid repository clone.

## Error Handling

### Scenario 1: Local file missing
```
⚠️  Local file not found: /path/to/file, trying online...
```
Falls back to GitHub download.

### Scenario 2: GitHub 404 (file not pushed)
```
❌ File not found on GitHub (404): filename
ℹ️  The file may not be pushed to GitHub yet
```
Clear indication that file needs to be pushed.

### Scenario 3: Other download errors
```
❌ Failed to download filename (HTTP 500)
```
Reports actual HTTP error code.

## Version History
- **v1.8**: LOCAL_MODE implementation added
- Purpose: Enable local testing before GitHub push
- Date: Current session

## Testing Status
✅ LOCAL_MODE detection works correctly
✅ Visual feedback displays properly
✅ File copying from local directory successful
✅ Subdirectory handling (modules/) works
✅ Fallback to online download functional
✅ Error messages improved and contextual

## Next Steps
1. Test complete installation in LOCAL_MODE
2. Push to GitHub
3. Test online mode after push
4. Verify both modes work correctly

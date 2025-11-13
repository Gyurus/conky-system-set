#!/bin/bash
# Enhanced Conky Removal Script with Failsafe Features
# This script safely removes all Conky configuration and files with comprehensive error handling

# Get version from VERSION file if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/VERSION" ]; then
    SCRIPT_VERSION=$(cat "$SCRIPT_DIR/VERSION" | tr -d '\n')
elif [ -f "$HOME/VERSION" ]; then
    SCRIPT_VERSION=$(cat "$HOME/VERSION" | tr -d '\n')
else
    SCRIPT_VERSION="1.9.1"  # Fallback version
fi

# Script safety features
BACKUP_DIR="$HOME/.conky_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
FORCE_REMOVAL=false
BACKUP_ENABLED=true

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\echo ""
echo "🔄 Processing autostart entries..."
safe_remove "$HOME/.config/autostart/conky.desktop" "Autostart entry" || ((removal_errors++))

# Check if autostart directory is now empty and was likely created for conky
if [ -d "$HOME/.config/autostart" ]; then
    local autostart_file_count=$(find "$HOME/.config/autostart" -type f | wc -l)
    if [ "$autostart_file_count" -eq 0 ]; then
        if [ "$DRY_RUN" = true ]; then
            print_status "info" "DRY RUN: Autostart directory is empty, would consider removing"
        elif [ "$FORCE_REMOVAL" = false ]; then
            echo ""
            read -p "   ❓ Autostart directory is empty. Remove it? (y/N): " confirm_autostart_dir
            if [[ "$confirm_autostart_dir" =~ ^[Yy]$ ]]; then
                if rmdir "$HOME/.config/autostart" 2>/dev/null; then
                    print_status "success" "Empty autostart directory removed"
                else
                    print_status "warning" "Could not remove autostart directory"
                fi
            else
                print_status "info" "Keeping empty autostart directory (user choice)"
            fi
        else
            # Force removal - remove if empty
            if rmdir "$HOME/.config/autostart" 2>/dev/null; then
                print_status "success" "Empty autostart directory removed"
            fi
        fi
    else
        print_status "info" "Autostart directory contains $autostart_file_count other file(s), keeping"
    fi
fi[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    case $1 in
        "success") echo -e "${GREEN}✅ $2${NC}" ;;
        "error") echo -e "${RED}❌ $2${NC}" ;;
        "warning") echo -e "${YELLOW}⚠️  $2${NC}" ;;
        "info") echo -e "${BLUE}ℹ️  $2${NC}" ;;
        *) echo "$2" ;;
    esac
}

# Function to safely remove file with error checking
safe_remove() {
    local file_path="$1"
    local description="$2"
    
    if [ ! -e "$file_path" ]; then
        print_status "info" "$description: Not found (already clean)"
        return 0
    fi
    
    # Backup if enabled
    if [ "$BACKUP_ENABLED" = true ] && [ -f "$file_path" ]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name=$(basename "$file_path")
        cp "$file_path" "$BACKUP_DIR/$backup_name" 2>/dev/null && \
            print_status "info" "Backed up: $file_path"
    fi
    
    # Dry run check
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "DRY RUN: Would remove $file_path"
        return 0
    fi
    
    # Actual removal with error checking
    if rm -f "$file_path" 2>/dev/null; then
        print_status "success" "$description: Removed"
        return 0
    else
        print_status "error" "$description: Failed to remove (check permissions)"
        return 1
    fi
}

# Function to safely remove directory
safe_remove_dir() {
    local dir_path="$1"
    local description="$2"
    
    if [ ! -d "$dir_path" ]; then
        print_status "info" "$description: Not found"
        return 0
    fi
    
    # Check directory contents more intelligently
    local total_files=$(find "$dir_path" -type f | wc -l)
    local conky_files=$(find "$dir_path" -type f \( -name "conky.conf" -o -name ".conky_*" \) | wc -l)
    local other_files=$((total_files - conky_files))
    
    if [ "$total_files" -eq 0 ]; then
        # Directory is empty
        if [ "$DRY_RUN" = true ]; then
            print_status "info" "DRY RUN: Would remove empty directory $dir_path"
            return 0
        fi
        
        if rmdir "$dir_path" 2>/dev/null; then
            print_status "success" "$description: Empty directory removed"
            return 0
        else
            print_status "warning" "$description: Could not remove empty directory"
            return 1
        fi
    elif [ "$other_files" -gt 0 ]; then
        # Directory contains non-conky files
        print_status "warning" "$description: Contains $other_files non-conky file(s), keeping directory"
        
        # Still try to remove any remaining conky files
        if [ "$conky_files" -gt 0 ]; then
            if [ "$DRY_RUN" = true ]; then
                print_status "info" "DRY RUN: Would remove $conky_files remaining conky file(s)"
            else
                find "$dir_path" -type f \( -name "conky.conf" -o -name ".conky_*" \) -delete 2>/dev/null
                print_status "info" "$description: Removed $conky_files remaining conky file(s)"
            fi
        fi
        return 0
    else
        # Directory contains only conky files - safe to remove completely
        if [ "$DRY_RUN" = true ]; then
            print_status "info" "DRY RUN: Would remove directory $dir_path (contains only $conky_files conky file(s))"
            return 0
        fi
        
        if rm -rf "$dir_path" 2>/dev/null; then
            print_status "success" "$description: Directory removed (contained only conky files)"
            return 0
        else
            print_status "warning" "$description: Could not remove directory"
            return 1
        fi
    fi
}

# Function to clean up backup files
clean_backup_files() {
    local backup_count=0
    local removed_count=0
    
    echo "🧹 Checking for backup files created by conky installation..."
    
    # Find backup files in common locations
    for pattern in \
        "$HOME/.config/"*.*.backup \
        "$HOME/"conkystartup.sh.*.backup \
        "$HOME/"rm-conkyset.sh.*.backup; do
        
        for backup_file in $pattern; do
            # Check if file exists and matches our backup pattern
            if [ -f "$backup_file" ] && [[ "$backup_file" =~ \.[0-9]{8}_[0-9]{6}\.backup$ ]]; then
                ((backup_count++))
                
                local description="Backup file: $(basename "$backup_file")"
                
                if [ "$DRY_RUN" = true ]; then
                    print_status "info" "DRY RUN: Would remove $backup_file"
                else
                    if [ "$FORCE_REMOVAL" = false ]; then
                        echo ""
                        read -p "   ❓ Remove backup file $(basename "$backup_file")? (y/N): " confirm_backup_removal
                        if [[ ! "$confirm_backup_removal" =~ ^[Yy]$ ]]; then
                            print_status "info" "$description: Kept (user choice)"
                            continue
                        fi
                    fi
                    
                    if rm -f "$backup_file" 2>/dev/null; then
                        print_status "success" "$description: Removed"
                        ((removed_count++))
                    else
                        print_status "error" "$description: Failed to remove"
                    fi
                fi
            fi
        done
    done
    
    if [ "$backup_count" -eq 0 ]; then
        print_status "info" "No backup files found"
    elif [ "$DRY_RUN" = true ]; then
        print_status "info" "DRY RUN: Found $backup_count backup file(s)"
    else
        print_status "success" "Processed $backup_count backup file(s), removed $removed_count"
    fi
}

# Function to stop Conky processes safely
stop_conky_processes() {
    echo -n "🛑 Checking for running Conky processes... "
    
    local conky_pids=$(pgrep -x conky)
    if [ -z "$conky_pids" ]; then
        print_status "info" "No running Conky processes found"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "DRY RUN: Would stop Conky processes: $conky_pids"
        return 0
    fi
    
    # Graceful termination first
    print_status "info" "Found Conky process(es): $conky_pids"
    echo "   Attempting graceful shutdown..."
    
    if pkill -TERM conky; then
        sleep 2
        
        # Check if still running
        if pgrep -x conky >/dev/null; then
            print_status "warning" "Graceful shutdown failed, forcing termination..."
            pkill -KILL conky
            sleep 1
        fi
        
        if ! pgrep -x conky >/dev/null; then
            print_status "success" "All Conky processes stopped"
        else
            print_status "warning" "Some Conky processes are still running; continuing removal"
            return 0
        fi
    else
        print_status "warning" "Could not terminate Conky processes; continuing removal"
        return 0
    fi
}

# Function to create backup of configuration
create_backup() {
    if [ "$BACKUP_ENABLED" = false ]; then
        return 0
    fi
    
    print_status "info" "Creating backup in: $BACKUP_DIR"
    
    if ! mkdir -p "$BACKUP_DIR"; then
        print_status "error" "Failed to create backup directory"
        BACKUP_ENABLED=false
        return 1
    fi
    
    # Create backup info file with date and time
    cat > "$BACKUP_DIR/backup_info.txt" << EOF
Conky Backup Information
========================
Created: $(date '+%Y-%m-%d %H:%M:%S')
Script Version: $SCRIPT_VERSION
Original Location: $HOME/.config/conky/
Backup Location: $BACKUP_DIR

To restore this backup:
1. Copy files back to their original locations
2. Run: chmod +x ~/conkystartup.sh ~/rm-conkyset.sh
3. Run: ~/conkystartup.sh

Files backed up:
EOF

    # List what will be backed up
    for file in \
        "$HOME/.config/conky/conky.conf" \
        "$HOME/.config/conky/.conky_iface" \
        "$HOME/.config/autostart/conky.desktop" \
        "$HOME/conkystartup.sh" \
        "$HOME/rm-conkyset.sh"; do
        
        if [ -f "$file" ]; then
            echo "- $(basename "$file")" >> "$BACKUP_DIR/backup_info.txt"
        fi
    done
    
    print_status "success" "Backup directory prepared"
}

# Function to show removal summary
show_removal_summary() {
    echo ""
    echo "🗑️  Files and directories to be processed:"
    echo "   Configuration:"
    echo "   • ~/.config/conky/conky.conf"
    echo "   • ~/.config/conky/.conky_iface"
    echo "   • ~/.config/conky/ (if empty or contains only conky files)"
    echo ""
    echo "   Autostart:"
    echo "   • ~/.config/autostart/conky.desktop"
    echo "   • ~/.config/autostart/ (if empty after cleanup)"
    echo ""
    echo "   Scripts:"
    echo "   • ~/conkystartup.sh"
    echo "   • ~/rm-conkyset.sh (this script)"
    echo ""
    echo "   Modules (autoupdate support):"
    echo "   • ~/modules/ directory"
    echo ""
    echo "   Update System:"
    echo "   • ~/.conky-system-set-skip-version"
    echo "   • ~/.conky-system-set-last-check"
    echo "   • ~/.conky-system-set-update-config"
    echo ""
    echo "   Backup Files:"
    echo "   • *.YYYYMMDD_HHMMSS.backup files (optional cleanup)"
    echo ""
    
    if [ "$BACKUP_ENABLED" = true ]; then
        print_status "info" "Backup will be created in: $BACKUP_DIR"
    else
        print_status "warning" "No backup will be created"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "DRY RUN MODE: No files will actually be removed"
    fi
}

# Function to print help/usage
print_help() {
    echo "Conky Removal Script v$SCRIPT_VERSION"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --dry-run      Show what would be removed without actually removing"
    echo "  --no-backup    Skip creating backup of configuration files"
    echo "  --force        Skip confirmation prompts"
    echo "  --help, -h     Show this help message and exit"
    echo ""
    echo "Examples:"
    echo "  $0 --dry-run"
    echo "  $0 --no-backup --force"
    echo ""
    echo "This script will remove all Conky configuration, autostart, and helper scripts."
    echo "Backups are created by default unless --no-backup is specified."
    echo ""
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-backup)
            BACKUP_ENABLED=false
            shift
            ;;
        --force)
            FORCE_REMOVAL=true
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            print_status "error" "Unknown option: $1"
            print_help
            exit 1
            ;;
    esac
done

# Main script starts here
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                    Conky System Monitor                     ║"
echo "║                   ENHANCED REMOVAL TOOL                     ║"
echo "║                      Version $SCRIPT_VERSION                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ "$DRY_RUN" = true ]; then
    print_status "info" "DRY RUN MODE ENABLED - No files will be removed"
    echo ""
fi

print_status "warning" "This will completely remove all Conky configuration and files."
echo ""

show_removal_summary

# Confirmation prompts (unless forced)
if [ "$FORCE_REMOVAL" = false ]; then
    echo ""
    read -p "❓ Do you want to continue with the removal? (y/n): " confirm_removal
    if [[ ! "$confirm_removal" =~ ^[Yy]$ ]]; then
        echo ""
        print_status "info" "Removal cancelled by user"
        echo ""
        echo "📝 Your Conky setup remains active and unchanged."
        echo ""
        echo "💡 To remove later, run this script again."
        echo "� Use '$0 --help' to see all available options."
        exit 0
    fi
    
    if [ "$BACKUP_ENABLED" = true ] && [ "$DRY_RUN" = false ]; then
        echo ""
        read -p "💾 Create backup before removal? (Y/n): " confirm_backup
        if [[ "$confirm_backup" =~ ^[Nn]$ ]]; then
            BACKUP_ENABLED=false
            print_status "warning" "Backup disabled by user choice"
        fi
    fi
fi

echo ""
if [ "$DRY_RUN" = true ]; then
    echo "🔍 DRY RUN: Analyzing what would be removed..."
else
    echo "🔄 Starting Conky removal process..."
fi
echo "════════════════════════════════════════════════"

# Create backup if enabled
if [ "$BACKUP_ENABLED" = true ] && [ "$DRY_RUN" = false ]; then
    create_backup
    echo ""
fi

# Stop running Conky processes
stop_conky_processes
echo ""

# Remove files with error checking
removal_errors=0

echo "📁 Processing configuration files..."
safe_remove "$HOME/.config/conky/conky.conf" "Main configuration file" || ((removal_errors++))
safe_remove "$HOME/.config/conky/.conky_iface" "Interface cache file" || ((removal_errors++))

echo ""
echo "📂 Processing directories..."
safe_remove_dir "$HOME/.config/conky" "Conky config directory"

echo ""
echo "� Processing autostart entries..."
safe_remove "$HOME/.config/autostart/conky.desktop" "Autostart entry" || ((removal_errors++))

echo ""
echo "📜 Processing scripts..."
safe_remove "$HOME/conkystartup.sh" "Startup script" || ((removal_errors++))

echo ""
echo "� Processing modules directory..."
safe_remove_dir "$HOME/modules" "Modules directory (autoupdate support)"

echo ""
echo "�🔧 Processing update system files..."
safe_remove "$HOME/.conky-system-set-skip-version" "Update skip version file" || ((removal_errors++))
safe_remove "$HOME/.conky-system-set-last-check" "Update check timestamp file" || ((removal_errors++))
safe_remove "$HOME/.conky-system-set-update-config" "Update configuration file" || ((removal_errors++))

echo ""
clean_backup_files

# Remove this script last with safer method
if [ "$DRY_RUN" = false ]; then
    echo ""
    print_status "info" "Scheduling removal of this script..."
    # Create a safe self-removal command that runs after this script exits
    (sleep 2; rm -f "$HOME/rm-conkyset.sh" 2>/dev/null) &
    print_status "info" "Removal script will be deleted in 2 seconds after completion"
fi

echo ""
echo "════════════════════════════════════════════════"

# Final status report
if [ "$DRY_RUN" = true ]; then
    print_status "info" "DRY RUN COMPLETED - No actual changes were made"
    echo ""
    echo "� Summary: This shows what would happen if you run the script normally."
    echo "💡 To perform actual removal, run: $0"
    echo "� To see all options, run: $0 --help"
elif [ $removal_errors -eq 0 ]; then
    print_status "success" "Conky removal completed successfully!"
    echo ""
    echo "✨ Your system is now clean of all Conky files."
    
    if [ "$BACKUP_ENABLED" = true ] && [ -d "$BACKUP_DIR" ]; then
        echo ""
        print_status "success" "Backup created at: $BACKUP_DIR"
        echo "📝 To restore later, copy files from backup directory back to their original locations."
    fi
    
    echo ""
    echo "💡 To reinstall Conky, run: ./conkyset.sh"
else
    print_status "warning" "Removal completed with $removal_errors error(s)"
    echo ""
    echo "⚠️  Some files may not have been removed due to permission issues."
    echo "🔧 You may need to remove them manually with sudo privileges."
    
    if [ "$BACKUP_ENABLED" = true ] && [ -d "$BACKUP_DIR" ]; then
        echo ""
        print_status "info" "Partial backup available at: $BACKUP_DIR"
    fi
fi

echo ""
echo "👋 Removal script finished."

# Only exit if not removing self (to prevent "Text file busy" error)
if [ "$DRY_RUN" = true ]; then
    exit 0
fi

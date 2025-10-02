#!/bin/bash
# Enhanced Conky Removal Script with Failsafe Features
# This script safely removes all Conky configuration and files with comprehensive error handling

# Script version and safety features
SCRIPT_VERSION="2.0"
BACKUP_DIR="$HOME/.conky_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false
FORCE_REMOVAL=false
BACKUP_ENABLED=true

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    
    # Check if directory is empty or contains only our files
    local file_count=$(find "$dir_path" -type f | wc -l)
    
    if [ "$file_count" -gt 0 ]; then
        print_status "warning" "$description: Contains $file_count file(s), keeping directory"
        return 0
    fi
    
    if [ "$DRY_RUN" = true ]; then
        print_status "info" "DRY RUN: Would remove empty directory $dir_path"
        return 0
    fi
    
    if rmdir "$dir_path" 2>/dev/null; then
        print_status "success" "$description: Empty directory removed"
        return 0
    else
        print_status "warning" "$description: Could not remove directory"
        return 1
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
    echo "   • ~/.config/conky/ (if empty)"
    echo ""
    echo "   Autostart:"
    echo "   • ~/.config/autostart/conky.desktop"
    echo ""
    echo "   Scripts:"
    echo "   • ~/conkystartup.sh"
    echo "   • ~/rm-conkyset.sh (this script)"
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

# Remove this script last
if [ "$DRY_RUN" = false ]; then
    echo ""
    print_status "info" "Removing this script in 3 seconds..."
    sleep 1
    print_status "info" "2..."
    sleep 1
    print_status "info" "1..."
    sleep 1
    safe_remove "$HOME/rm-conkyset.sh" "Removal script (this file)"
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

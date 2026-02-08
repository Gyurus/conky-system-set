#!/bin/bash
# install-online.sh - Conky System Set Online Installer
# Downloads and sets up the complete conky-system-set from GitHub

set -e  # Exit on error

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default flags
NONINTERACTIVE=false
FULL_WIPE=false

# Parse basic flags early (before tty handling)
for arg in "$@"; do
    case "$arg" in
        -y|--yes|--noninteractive)
            NONINTERACTIVE=true
            ;;
        --full-wipe|--wipe)
            FULL_WIPE=true
            ;;
    esac
done

# Ensure we can read from terminal even when piped from curl
if [ "$NONINTERACTIVE" != true ] && [ ! -t 0 ]; then
    exec < /dev/tty
fi

# Configuration
REPO_OWNER="Gyurus"
REPO_NAME="conky-system-set"
BRANCH="main"  # Change to "feature/multi-monitor-support" for dev version
INSTALL_DIR="$HOME/.conky-system-set"
GITHUB_RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"
GITHUB_API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}"

# Check if running from local repo (for testing)
LOCAL_MODE=false
if [ -f "$SCRIPT_DIR/conkyset.sh" ] && [ -f "$SCRIPT_DIR/conky.template.conf" ]; then
    LOCAL_MODE=true
fi

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Conky System Set - Online Installer v$INSTALLER_VERSION           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    if [ "$LOCAL_MODE" = true ]; then
        print_info "🔧 LOCAL MODE: Running from repository directory"
        print_info "Files will be copied locally (for testing)"
        echo ""
    fi
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}▶ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Resolve installer version (local VERSION or remote VERSION/release)
resolve_installer_version() {
    local version=""

    if [ "$LOCAL_MODE" = true ] && [ -f "$SCRIPT_DIR/VERSION" ]; then
        version=$(tr -d '\n' < "$SCRIPT_DIR/VERSION")
        echo "$version"
        return
    fi

    if command -v curl >/dev/null 2>&1; then
        version=$(curl -fsSL "$GITHUB_RAW_URL/VERSION" 2>/dev/null | tr -d '\n')
    elif command -v wget >/dev/null 2>&1; then
        version=$(wget -qO- "$GITHUB_RAW_URL/VERSION" 2>/dev/null | tr -d '\n')
    fi

    if [ -z "$version" ]; then
        if command -v curl >/dev/null 2>&1; then
            version=$(curl -fsSL "$GITHUB_API_URL/releases/latest" 2>/dev/null \
                | grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
        elif command -v wget >/dev/null 2>&1; then
            version=$(wget -qO- "$GITHUB_API_URL/releases/latest" 2>/dev/null \
                | grep -o '"tag_name":[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4)
        fi
        version="${version#v}"
    fi

    if [ -z "$version" ]; then
        version="unknown"
    fi

    echo "$version"
}

INSTALLER_VERSION=$(resolve_installer_version)

# Prompt for top position preference (left/middle/right)
prompt_position_choice() {
    local choice
    echo ""
    echo "Choose top placement for Conky:"
    echo "  1. Left top"
    echo "  2. Middle top"
    echo "  3. Right top"
    echo -n "Choice [3]: "
    read -r choice
    case "$choice" in
        1)
            echo "top_left"
            ;;
        2)
            # Map "middle top" to the closest supported position.
            echo "center"
            ;;
        3|"")
            echo "top_right"
            ;;
        *)
            echo "top_right"
            ;;
    esac
}

# Prompt for monitor selection if multiple monitors are connected
prompt_monitor_choice() {
    if ! command_exists xrandr; then
        return 0
    fi

    local -a monitor_names
    local -a monitor_primary
    local line name is_primary
    while IFS= read -r line; do
        name=$(echo "$line" | awk '{print $1}')
        if echo "$line" | grep -q " primary "; then
            is_primary="yes"
        else
            is_primary="no"
        fi
        monitor_names+=("$name")
        monitor_primary+=("$is_primary")
    done < <(xrandr --query | grep ' connected')

    if [ "${#monitor_names[@]}" -le 1 ]; then
        return 0
    fi

    echo ""
    echo "Select monitor for Conky (multi-monitor detected):"
    local default_choice=1
    local i
    for i in "${!monitor_names[@]}"; do
        local label="$((i+1)). ${monitor_names[$i]}"
        if [ "${monitor_primary[$i]}" = "yes" ]; then
            label+=" (primary)"
            default_choice=$((i+1))
        fi
        echo "  $label"
    done
    echo -n "Choice [${default_choice}]: "
    read -r choice
    if [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#monitor_names[@]}" ]; then
        echo "${monitor_names[$((choice-1))]}"
        return 0
    fi
    echo "${monitor_names[$((default_choice-1))]}"
}

# Build setup arguments for conkyset.sh
configure_setup_preferences() {
    SETUP_ARGS=()
    local position monitor
    position=$(prompt_position_choice)
    if [ -n "$position" ]; then
        SETUP_ARGS+=("--position" "$position")
    fi
    monitor=$(prompt_monitor_choice)
    if [ -n "$monitor" ]; then
        SETUP_ARGS+=("--monitor" "$monitor")
    fi
}

# Check prerequisites
check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for required tools
    if ! command_exists curl && ! command_exists wget; then
        missing_deps+=("curl or wget")
    fi
    
    if ! command_exists git; then
        missing_deps+=("git")
    fi
    
    if ! command_exists jq; then
        print_warning "jq not found (optional, but recommended for better GitHub API handling)"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Please install them first:"
        echo "  Ubuntu/Debian: sudo apt install curl git jq"
        echo "  Fedora: sudo dnf install curl git jq"
        echo "  Arch: sudo pacman -S curl git jq"
        return 1
    fi
    
    print_success "All prerequisites satisfied"
    return 0
}

# Download file using curl or wget
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-file}"
    
    # If in local mode, copy from local directory (skip API endpoints)
    if [ "$LOCAL_MODE" = true ] && [[ "$url" != "$GITHUB_API_URL"* ]]; then
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
            else
                print_error "Failed to download $description (HTTP $http_code)"
                return 1
            fi
        fi
    elif command_exists wget; then
        if wget -q "$url" -O "$output" 2>/dev/null; then
            return 0
        else
            print_error "Failed to download $description from $url"
            return 1
        fi
    else
        print_error "Neither curl nor wget available"
        return 1
    fi
}

# Get list of files from GitHub repository
get_repo_files() {
    print_step "Fetching repository file list..." >&2
    
    local tree_url="${GITHUB_API_URL}/git/trees/${BRANCH}?recursive=1"
    local temp_file="/tmp/conky-repo-tree.json"
    
    if ! download_file "$tree_url" "$temp_file" "repository tree"; then
        return 1
    fi
    
    if command_exists jq; then
        # Use jq for better parsing
        jq -r '.tree[] | select(.type=="blob") | .path' "$temp_file" 2>/dev/null
    else
        # Fallback to grep/sed
        grep -o '"path":"[^"]*"' "$temp_file" | sed 's/"path":"//;s/"$//'
    fi
    
    rm -f "$temp_file"
}

# Create installation directory structure
create_directory_structure() {
    print_step "Creating directory structure..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/modules"
    
    print_success "Directory structure created"
}

# Download essential files
download_essential_files() {
    print_step "Downloading essential files from GitHub..."
    
    local essential_files=(
        "conkyset.sh"
        "conkystartup.sh"
        "rm-conkyset.sh"
        "conky.template.conf"
        "VERSION"
        "README.md"
        "modules/update.sh"
        "modules/monitor.sh"
        "modules/iface.sh"
        "modules/weather.sh"
        "modules/gpu.sh"
        "modules/process.sh"
    )
    
    local success_count=0
    local fail_count=0
    
    for file in "${essential_files[@]}"; do
        local url="${GITHUB_RAW_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        # Create parent directory if needed
        mkdir -p "$(dirname "$output")"
        
        echo -n "   Downloading: $file ... "
        if download_file "$url" "$output" "$file"; then
            print_success "✓"
            ((success_count++))
        else
            print_error "✗"
            ((fail_count++))
        fi
    done
    
    echo ""
    print_info "Downloaded: $success_count files, Failed: $fail_count files"
    
    if [ "$fail_count" -gt 0 ]; then
        print_warning "Some files failed to download"
        echo -n "Continue anyway? (y/N): "
        read -r continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Download all repository files (optional)
download_all_files() {
    if [ "$NONINTERACTIVE" = true ]; then
        print_info "Skipping optional files (non-interactive mode)"
        return 0
    fi
    print_step "Would you like to download ALL files including tests and docs?"
    echo -n "This includes test scripts, documentation, etc. (y/N): "
    read -r download_all
    
    if [[ ! "$download_all" =~ ^[Yy]$ ]]; then
        print_info "Skipping optional files"
        return 0
    fi
    
    print_step "Downloading all repository files..."
    
    local files
    files=$(get_repo_files)
    
    if [ -z "$files" ]; then
        print_warning "Could not fetch complete file list, continuing with essentials only"
        return 0
    fi
    
    local count=0
    while IFS= read -r file; do
        # Skip files we already downloaded
        if [ -f "${INSTALL_DIR}/${file}" ]; then
            continue
        fi
        
        local url="${GITHUB_RAW_URL}/${file}"
        local output="${INSTALL_DIR}/${file}"
        
        mkdir -p "$(dirname "$output")"
        
        if download_file "$url" "$output" "$file"; then
            ((count++))
        fi
    done <<< "$files"
    
    print_success "Downloaded $count additional files"
}

# Validate downloaded shell scripts for syntax errors
validate_downloaded_scripts() {
    print_step "Validating downloaded scripts..."

    local failed=0
    local file

    while IFS= read -r -d '' file; do
        if ! bash -n "$file" 2>/dev/null; then
            print_error "Syntax check failed: $file"
            failed=$((failed+1))
        fi
    done < <(find "$INSTALL_DIR" -type f -name "*.sh" -print0)

    if [ "$failed" -gt 0 ]; then
        print_error "Downloaded scripts failed validation. Please re-run the installer."
        return 1
    fi

    print_success "Script validation passed"
    return 0
}

# Make scripts executable
set_permissions() {
    print_step "Setting executable permissions..."
    
    chmod +x "$INSTALL_DIR/conkyset.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/conkystartup.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR/rm-conkyset.sh" 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/test-*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    
    print_success "Permissions set"
}

# Check and clean previous installation
check_previous_installation() {
    print_step "Checking for previous installation..."
    
    local found_items=()
    local cleanup_needed=false
    
    # Check installation directory
    if [ -d "$INSTALL_DIR" ]; then
        found_items+=("Installation directory: $INSTALL_DIR")
        cleanup_needed=true
    fi
    
    # Check home directory scripts
    if [ -f "$HOME/conkyset.sh" ] || [ -L "$HOME/conkyset.sh" ]; then
        found_items+=("Script: ~/conkyset.sh")
        cleanup_needed=true
    fi
    
    if [ -f "$HOME/conkystartup.sh" ] || [ -L "$HOME/conkystartup.sh" ]; then
        found_items+=("Script: ~/conkystartup.sh")
        cleanup_needed=true
    fi
    
    if [ -f "$HOME/rm-conkyset.sh" ] || [ -L "$HOME/rm-conkyset.sh" ]; then
        found_items+=("Script: ~/rm-conkyset.sh")
        cleanup_needed=true
    fi
    
    # Check for modules directory
    if [ -d "$HOME/modules" ]; then
        found_items+=("Modules directory: ~/modules")
        cleanup_needed=true
    fi
    
    # Check for VERSION file
    if [ -f "$HOME/VERSION" ]; then
        found_items+=("Version file: ~/VERSION")
        cleanup_needed=true
    fi
    
    # Check .config/conky directory (correct path)
    if [ -d "$HOME/.config/conky" ]; then
        found_items+=("Config directory: ~/.config/conky")
        cleanup_needed=true
    fi
    
    # Check old .conky directory (legacy)
    if [ -d "$HOME/.conky" ]; then
        found_items+=("Old config directory: ~/.conky (legacy)")
        cleanup_needed=true
    fi
    
    # Check running Conky processes
    if pgrep -x conky > /dev/null 2>&1; then
        found_items+=("Running Conky processes")
        cleanup_needed=true
    fi
    
    # Check autostart
    local autostart_file=""
    if [ -f "$HOME/.config/autostart/conky.desktop" ]; then
        found_items+=("Autostart: ~/.config/autostart/conky.desktop")
        autostart_file="$HOME/.config/autostart/conky.desktop"
        cleanup_needed=true
    elif [ -f "$HOME/.config/autostart/conkystartup.desktop" ]; then
        found_items+=("Autostart: ~/.config/autostart/conkystartup.desktop")
        autostart_file="$HOME/.config/autostart/conkystartup.desktop"
        cleanup_needed=true
    fi
    
    if [ "$cleanup_needed" = false ]; then
        print_success "No previous installation found"
        return 0
    fi
    
    # Show what was found
    print_warning "Previous installation detected:"
    echo ""
    for item in "${found_items[@]}"; do
        echo "   • $item"
    done
    echo ""
    
    if [ "$NONINTERACTIVE" = true ]; then
        remove_prev="y"
    else
        echo -n "Remove previous installation and continue? (Y/n): "
        read -r remove_prev
    fi
    
    if [[ "$remove_prev" =~ ^[Nn]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    # Perform cleanup
    print_info "Removing previous installation..."
    
    # Stop Conky processes
    if pgrep -x conky > /dev/null 2>&1; then
        echo "   Stopping Conky processes..."
        pkill -x conky 2>/dev/null || killall conky 2>/dev/null || true
        sleep 1
    fi
    
    # Remove scripts (files and symlinks)
    echo "   Removing scripts..."
    rm -f "$HOME/conkyset.sh" "$HOME/conkystartup.sh" "$HOME/rm-conkyset.sh" 2>/dev/null || true
    
    # Remove modules directory
    if [ -d "$HOME/modules" ]; then
        echo "   Removing modules directory..."
        rm -rf "$HOME/modules" 2>/dev/null || true
    fi
    
    # Remove VERSION file
    if [ -f "$HOME/VERSION" ]; then
        echo "   Removing VERSION file..."
        rm -f "$HOME/VERSION" 2>/dev/null || true
    fi
    
    # Remove installation directory
    if [ -d "$INSTALL_DIR" ]; then
        echo "   Removing installation directory..."
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
    fi
    
    # Remove .config/conky directory (ask for confirmation)
    if [ -d "$HOME/.config/conky" ]; then
        if [ "$FULL_WIPE" = true ]; then
            remove_config="y"
        elif [ "$NONINTERACTIVE" = true ]; then
            remove_config="n"
        else
            echo -n "   Remove configuration directory ~/.config/conky? (y/N): "
            read -r remove_config
        fi
        if [[ "$remove_config" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.config/conky" 2>/dev/null || true
            echo "   Configuration directory removed"
        else
            echo "   Configuration directory kept"
        fi
    fi
    
    # Remove old .conky directory (legacy)
    if [ -d "$HOME/.conky" ]; then
        if [ "$FULL_WIPE" = true ]; then
            remove_old_config="y"
        elif [ "$NONINTERACTIVE" = true ]; then
            remove_old_config="n"
        else
            echo -n "   Remove old configuration directory ~/.conky? (y/N): "
            read -r remove_old_config
        fi
        if [[ "$remove_old_config" =~ ^[Yy]$ ]]; then
            rm -rf "$HOME/.conky" 2>/dev/null || true
            echo "   Old configuration directory removed"
        else
            echo "   Old configuration directory kept"
        fi
    fi
    
    # Remove autostart
    if [ -n "$autostart_file" ] && [ -f "$autostart_file" ]; then
        echo "   Removing autostart entry..."
        rm -f "$autostart_file" 2>/dev/null || true
    fi
    
    # Remove update check files
    rm -f "$HOME/.conky-system-set-last-check" 2>/dev/null || true
    rm -f "$HOME/.conky-system-set-skip-version" 2>/dev/null || true
    rm -f "$HOME/.conky-system-set-update-config" 2>/dev/null || true
    
    print_success "Previous installation removed successfully"
    echo ""
    
    return 0
}

# Create symlinks or copy to home directory
setup_home_links() {
    print_step "Setting up quick access..."
    
    if [ "$NONINTERACTIVE" = true ]; then
        print_info "Creating symlinks (non-interactive mode)"
        ln -sf "$INSTALL_DIR/conkyset.sh" "$HOME/conkyset.sh"
        ln -sf "$INSTALL_DIR/conkystartup.sh" "$HOME/conkystartup.sh"
        ln -sf "$INSTALL_DIR/rm-conkyset.sh" "$HOME/rm-conkyset.sh"
        print_success "Symlinks created in $HOME"
        return
    fi

    echo ""
    echo "How would you like to access the scripts?"
    echo "  1. Create symlinks in home directory (recommended)"
    echo "  2. Copy scripts to home directory (not recommended)"
    echo "  3. Skip (access from install directory only)"
    echo -n "Choice [1]: "
    read -r setup_choice
    
    case "$setup_choice" in
        2)
            # Copy files
            print_warning "⚠️  WARNING: Copying breaks module loading!"
            print_warning "Modules directory will not be accessible"
            echo -n "Are you sure? (y/N): "
            read -r confirm_copy
            if [[ ! "$confirm_copy" =~ ^[Yy]$ ]]; then
                print_info "Switching to symlinks instead..."
                ln -sf "$INSTALL_DIR/conkyset.sh" "$HOME/conkyset.sh"
                ln -sf "$INSTALL_DIR/conkystartup.sh" "$HOME/conkystartup.sh"
                ln -sf "$INSTALL_DIR/rm-conkyset.sh" "$HOME/rm-conkyset.sh"
                print_success "Symlinks created in $HOME"
                return
            fi
            print_info "Copying scripts to home directory..."
            cp "$INSTALL_DIR/conkyset.sh" "$HOME/conkyset.sh"
            cp "$INSTALL_DIR/conkystartup.sh" "$HOME/conkystartup.sh"
            cp "$INSTALL_DIR/rm-conkyset.sh" "$HOME/rm-conkyset.sh"
            chmod +x "$HOME/conkyset.sh" "$HOME/conkystartup.sh" "$HOME/rm-conkyset.sh"
            print_warning "Scripts copied to $HOME (modules will not work)"
            ;;
        3)
            print_info "Skipping home directory setup"
            ;;
        *)
            # Create symlinks (default and recommended)
            print_info "Creating symlinks..."
            ln -sf "$INSTALL_DIR/conkyset.sh" "$HOME/conkyset.sh"
            ln -sf "$INSTALL_DIR/conkystartup.sh" "$HOME/conkystartup.sh"
            ln -sf "$INSTALL_DIR/rm-conkyset.sh" "$HOME/rm-conkyset.sh"
            print_success "Symlinks created in $HOME"
            ;;
    esac
}

# Show installation summary
show_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              INSTALLATION COMPLETE!                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    print_success "Conky System Set v$INSTALLER_VERSION has been installed!"
    echo ""
    echo "📁 Installation directory: $INSTALL_DIR"
    echo ""
    echo "🚀 NEXT STEPS:"
    echo "═════════════"
    echo ""
    echo "1. Run the setup script:"
    if [ -f "$HOME/conkyset.sh" ]; then
        echo "   ~/conkyset.sh"
    else
        echo "   cd $INSTALL_DIR && ./conkyset.sh"
    fi
    echo ""
    echo "2. For help and options:"
    echo "   ~/conkyset.sh --help"
    echo ""
    echo "3. To start Conky manually after setup:"
    echo "   ~/conkystartup.sh"
    echo ""
    echo "4. To remove Conky setup:"
    echo "   ~/rm-conkyset.sh"
    echo ""
    echo "📚 ADDITIONAL RESOURCES:"
    echo "═══════════════════════"
    echo ""
    echo "• README: $INSTALL_DIR/README.md"
    echo "• GitHub: https://github.com/${REPO_OWNER}/${REPO_NAME}"
    echo "• Report issues: https://github.com/${REPO_OWNER}/${REPO_NAME}/issues"
    echo ""
    echo "💡 TIP: The setup script supports multi-monitor configurations!"
    echo ""
}

# Main installation flow
main() {
    print_header
    
    echo "This script will download and install Conky System Set from GitHub."
    echo "Repository: https://github.com/${REPO_OWNER}/${REPO_NAME}"
    echo "Branch: $BRANCH"
    echo "Install location: $INSTALL_DIR"
    echo ""
    
    # Check and clean previous installation
    check_previous_installation
    
    if [ "$NONINTERACTIVE" = true ]; then
        confirm="y"
    else
        echo -n "Continue with installation? (Y/n): "
        read -r confirm
    fi
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_info "Installation cancelled"
        exit 0
    fi
    
    echo ""
    
    # Run installation steps
    if ! check_prerequisites; then
        exit 1
    fi
    
    echo ""
    create_directory_structure
    
    echo ""
    if ! download_essential_files; then
        print_error "Failed to download essential files"
        exit 1
    fi
    
    echo ""
    download_all_files

    echo ""
    if ! validate_downloaded_scripts; then
        exit 1
    fi
    
    echo ""
    set_permissions
    
    echo ""
    setup_home_links
    
    show_summary
    
    # Offer to run setup immediately
    echo ""
    if [ "$NONINTERACTIVE" = true ]; then
        run_now="n"
    else
        echo -n "Would you like to run the setup now? (y/N): "
        read -r run_now
    fi
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Starting Conky setup..."
        echo ""
        # Change to installation directory so conkyset.sh can find required scripts
        cd "$INSTALL_DIR"
        configure_setup_preferences
        if [ "${#SETUP_ARGS[@]}" -gt 0 ]; then
            exec "./conkyset.sh" "${SETUP_ARGS[@]}"
        else
            exec "./conkyset.sh"
        fi
    fi
    
    echo ""
    print_success "Installation complete! Run ~/conkyset.sh to begin setup."
    echo ""
}

# Handle Ctrl+C gracefully
trap 'echo ""; print_warning "Installation interrupted"; exit 130' INT TERM

# Run main installation
main "$@"

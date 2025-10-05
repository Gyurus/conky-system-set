#!/bin/bash
# Conky System Set - Online Installer
# Downloads and sets up the complete conky-system-set from GitHub

set -e  # Exit on error

# Ensure we can read from terminal even when piped from curl
if [ ! -t 0 ]; then
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    echo "║        Conky System Set - Online Installer v1.8.3           ║"
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
    print_step "Fetching repository file list..."
    
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
    
    if [ $fail_count -gt 0 ]; then
        print_warning "Some files failed to download"
        echo -n "Continue anyway? (y/N): "
        read continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Download all repository files (optional)
download_all_files() {
    print_step "Would you like to download ALL files including tests and docs?"
    echo -n "This includes test scripts, documentation, etc. (y/N): "
    read download_all
    
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

# Create symlinks or copy to home directory
setup_home_links() {
    print_step "Setting up quick access..."
    
    echo ""
    echo "How would you like to access the scripts?"
    echo "  1. Create symlinks in home directory (recommended)"
    echo "  2. Copy scripts to home directory (not recommended)"
    echo "  3. Skip (access from install directory only)"
    echo -n "Choice [1]: "
    read setup_choice
    
    case "$setup_choice" in
        2)
            # Copy files
            print_warning "⚠️  WARNING: Copying breaks module loading!"
            print_warning "Modules directory will not be accessible"
            echo -n "Are you sure? (y/N): "
            read confirm_copy
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
    print_success "Conky System Set v1.8.3 has been installed!"
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
    
    # Check if already installed
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Installation directory already exists: $INSTALL_DIR"
        echo -n "Overwrite existing installation? (y/N): "
        read overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
        print_info "Removing existing installation..."
        rm -rf "$INSTALL_DIR"
    fi
    
    echo -n "Continue with installation? (Y/n): "
    read confirm
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
    set_permissions
    
    echo ""
    setup_home_links
    
    show_summary
    
    # Offer to run setup immediately
    echo ""
    echo -n "Would you like to run the setup now? (y/N): "
    read run_now
    if [[ "$run_now" =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Starting Conky setup..."
        echo ""
        if [ -f "$HOME/conkyset.sh" ]; then
            exec "$HOME/conkyset.sh"
        else
            exec "$INSTALL_DIR/conkyset.sh"
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

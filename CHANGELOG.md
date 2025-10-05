# Changelog

All notable changes to Conky System Set are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.8.3] - 2025-10-05

### Fixed
- **Critical Installer Bug**: Fixed stdin reading when installer is piped from curl
- Script now properly redirects stdin from `/dev/tty` when not running in a terminal
- Resolves issue where `read` commands would fail during `curl ... | bash` installation
- User prompts now work correctly in piped installation scenarios

### Technical Details
- **Problem**: When running `curl -fsSL ... | bash`, stdin is consumed by curl, causing `read` commands to fail
- **Solution**: Added automatic stdin redirection from `/dev/tty` if not running in a terminal
- **Impact**: Without this fix, installer would hang or exit at first user prompt
- **Now**: Interactive prompts work correctly even when piped from curl

## [1.8.2] - 2025-10-05

### Changed
- **Documentation Consolidation**: Merged all documentation into comprehensive CHANGELOG.md
- Repository cleanup: Removed 24 unnecessary files (test scripts, backup files, redundant docs)
- Improved repository structure following industry best practices
- Updated README.md with clear documentation section

### Removed
- 10 redundant markdown documentation files (content preserved in CHANGELOG.md)
- 12 test and debug scripts (not needed for production)
- 2 backup configuration files
- **Total cleanup**: 3,078 lines removed, repository now cleaner and easier to navigate

### Documentation
- Created comprehensive CHANGELOG.md following Keep a Changelog format
- All version history and technical details preserved
- Better organization: README.md (getting started), CHANGELOG.md (history), ONLINE_INSTALL.md (installation)
- Single source of truth for version history and changes

### Benefits
- Cleaner repository structure (15 files vs 39 files)
- Easier to navigate and understand
- No duplicate content to maintain
- Professional appearance following open source best practices

## [1.8.1] - 2025-10-05

### Critical Fix
- **Module Loading Errors**: Fixed critical issue where scripts copied to home directory couldn't find modules
- Changed default installation option from "copy" to "symlinks" (recommended)
- Added warnings and confirmation prompts when user chooses copy option
- Module paths now resolve correctly: `$(dirname "$0")/modules/` works with symlinks

### Added
- `fix-modules.sh` - Repair script for existing installations with module path issues
- Comprehensive troubleshooting section in ONLINE_INSTALL.md
- Detection and helpful error messages for module path problems

### Fixed
- Resolved `/home/user/modules/weather.sh: No such file or directory` errors
- Fixed `kill_conky: command not found` errors
- Fixed `get_monitor_config: command not found` errors
- All module sourcing now works correctly with symlinked scripts

### Changed
- Installer now defaults to creating symlinks (option 1) instead of copying files
- Enhanced user guidance during installation with clear recommendations
- Improved error messages with context about why failures occurred

### Documentation
- Added VERSION_1.8.1_CRITICAL_FIX.md with complete fix documentation
- Updated ONLINE_INSTALL.md with module path troubleshooting
- Enhanced installation examples to show symlink as default

## [1.8.0] - 2025-10-05

### Major Features

#### Online Installer
- **New**: Complete online installation system via GitHub
- Download and install directly: `curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash`
- Automatic prerequisite checking (curl/wget, git, jq, conky)
- Interactive setup with user prompts
- GitHub API integration for file discovery
- Smart fallback between curl and wget

#### LOCAL_MODE Support
- Automatic detection when running from repository directory
- Files copied locally during development/testing
- Prevents 404 errors before pushing to GitHub
- Visual feedback showing LOCAL_MODE status
- Seamless switching between local and online modes

#### Multi-Monitor Enhancements
- Improved monitor detection and selection flow
- Visual feedback with monitor list formatting
- Primary monitor marked with ⭐ symbol
- Numbered selection format [1], [2], [3]
- Removed duplicate information displays
- Streamlined user experience

### Fixed

#### Removal Script (5 Critical Issues)
1. **Update Files Cleanup**: Now removes `.conky-last-update` file
2. **Backup File Removal**: Cleans up all `.backup` files in .conky directory
3. **Smart Directory Logic**: Only removes .conky if empty or only contains conky configs
4. **Safe Self-Removal**: Uses background process to remove script after completion
5. **Autostart Validation**: Checks both old and new autostart file locations

#### Monitor Selection UX
- Removed duplicate monitor information display
- Show info once before asking for selection
- Cleaner, less confusing user interface
- Better visual formatting with consistent styling

#### 404 Download Errors
- Merged feature branch to main branch
- Recreated tags (v1.8, v1.8.1) on main branch
- All installer URLs now work correctly
- Files accessible from both main branch and version tags

### Added

#### New Files
- `install-online.sh` - Complete online installer (450+ lines)
- `modules/update.sh` - Update checking system with GitHub API integration
- `fix-modules.sh` - Quick fix for module path issues
- `ONLINE_INSTALL.md` - Comprehensive installation guide (500+ lines)
- `INSTALLER_LOCAL_MODE.md` - Developer testing guide
- `404_FIX_SUMMARY.md` - Resolution documentation for download issues

#### New Features
- Automatic update checking on script execution
- Configurable update check intervals (24 hours default)
- Non-intrusive update notifications
- Version comparison with semantic versioning
- Command-line flags: `--check-updates`, `--force-update-check`, `--skip-update-check`

### Changed

#### Version Display
- Added "v1.8" to main script banner
- Version now visible in all user-facing output
- Consistent version display across all scripts

#### Documentation
- Updated README.md with online installation section
- Added quick start guide with one-line installation
- Enhanced troubleshooting sections
- Added security considerations for online installation
- Comparison table: online vs manual installation

#### Installation Options
- Three installation modes: quick install, download & inspect, specific version
- Support for installing from main branch or specific tags
- Flexible script access: symlinks, copy, or directory-only
- Automatic directory structure creation

### Technical Improvements

#### Error Handling
- Better HTTP status code detection (404 vs other errors)
- Contextual error messages explaining causes
- Graceful fallbacks when files not available
- Smart detection of local vs remote scenarios

#### Code Quality
- Modular function design in installer
- Consistent error handling patterns
- Comprehensive input validation
- Safe file operations with error checking

#### GitHub Integration
- Raw content downloads from GitHub
- API queries for repository information
- Support for multiple branches
- Tag-based version installation

## [1.7-dev] - Previous Development

### Features
- Multi-monitor support foundation
- Monitor detection via xrandr
- Weather module integration
- GPU detection and monitoring
- Network interface selection
- Process monitoring

### Known Issues (Fixed in 1.8+)
- Removal script didn't clean up all files
- Monitor selection showed duplicate information
- No online installation method
- Manual setup required

## [1.6] - 2023-07-22

### Features
- Enhanced weather module with better location detection
- Improved error handling throughout
- Better sensor detection
- Configuration template improvements

### Fixed
- Various bug fixes and stability improvements
- Weather location setup improvements

---

## Migration Guide

### From v1.8 to v1.8.1

If you installed v1.8 and chose to copy scripts (option 1), you may have module loading errors.

**Quick Fix:**
```bash
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/fix-modules.sh | bash
```

**Manual Fix:**
```bash
# Remove copied scripts
rm ~/conkyset.sh ~/conkystartup.sh ~/rm-conkyset.sh

# Create proper symlinks
ln -sf ~/.conky-system-set/conkyset.sh ~/conkyset.sh
ln -sf ~/.conky-system-set/conkystartup.sh ~/conkystartup.sh
ln -sf ~/.conky-system-set/rm-conkyset.sh ~/rm-conkyset.sh
```

### From v1.6 to v1.8+

**Recommended: Fresh Installation**
```bash
# Remove old installation
~/rm-conkyset.sh

# Install v1.8.1
curl -fsSL https://raw.githubusercontent.com/Gyurus/conky-system-set/main/install-online.sh | bash
```

**Benefits of Upgrading:**
- Online installation and updates
- Better multi-monitor support
- Improved removal process
- Enhanced error handling
- Automatic update notifications

---

## Development Notes

### v1.8.1 Critical Fix Background

**Problem Identified:**
When users selected "copy to home directory" during installation, the scripts were copied to `~/conkyset.sh` but the modules stayed in `~/.conky-system-set/modules/`. Since the scripts use `$(dirname "$0")/modules/` to find modules, copied scripts looked for `~/modules/` which didn't exist.

**Root Cause:**
The installer defaulted to copying files (option 1) instead of creating symlinks. This broke the relative path resolution used by the scripts.

**Solution:**
- Changed default to symlinks (preserves directory structure)
- Added warnings for copy option
- Created repair script for affected installations
- Enhanced documentation with troubleshooting guide

**Impact:** 
All users who chose default option (copy) in v1.8 experienced complete functionality loss. v1.8.1 prevents this by making symlinks the default and warning about copy option.

### v1.8.0 404 Fix Background

**Problem Identified:**
Online installer returned 404 errors when trying to download files from GitHub.

**Root Cause:**
- All v1.8 code was developed on `feature/multi-monitor-support` branch
- Installer defaults to `BRANCH="main"`
- Files didn't exist on main branch
- Tags v1.8 and v1.8.1 pointed to feature branch

**Solution:**
- Merged feature branch into main via fast-forward merge
- Deleted and recreated tags on main branch
- Verified all URLs return HTTP 200
- Added comprehensive documentation

**Impact:**
No users could successfully run the online installer until this fix was deployed.

### Testing Checklist for Releases

- [ ] Code merged to main branch
- [ ] Tags created on main branch  
- [ ] Test installer download: `curl -I https://raw.githubusercontent.com/...`
- [ ] Test module files accessible
- [ ] Verify LOCAL_MODE still works
- [ ] Test on fresh system without local files
- [ ] Verify symlinks work correctly
- [ ] Test all command-line options
- [ ] Check update system works
- [ ] Verify removal script cleans everything

---

## Links

- **Repository**: https://github.com/Gyurus/conky-system-set
- **Issues**: https://github.com/Gyurus/conky-system-set/issues
- **Releases**: https://github.com/Gyurus/conky-system-set/releases

## License

This project follows the same license as the main repository.

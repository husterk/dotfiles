#!/bin/zsh

# ========================================================================
# macOS ARM Deploy Dotfiles Script
# ========================================================================
# This script deploys generated dotfiles using GNU Stow by:
# - Validating the generated dotfiles directory exists
# - Backing up existing dotfiles that would be overwritten
# - Using GNU Stow to create symlinks from generated dotfiles to home directory
# - Restoring dotfiles from previous backups
# - Providing clear feedback about deployment status
#
# Usage: ./deploy-dotfiles.sh [hostname] [options]
# Example: ./deploy-dotfiles.sh keith-macbook-pro
# Options:
#   --dry-run    Show what would be done without making changes
#   --restow     Remove and re-create symlinks (useful for updates)
#   --delete     Remove symlinks (unstow)
#   --restore    Restore dotfiles from a backup
# ========================================================================

set -e  # Exit on error

# Color output for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions for output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ------------------------------------------------------------------------
# Step 0: Parse Arguments and Setup Paths
# ------------------------------------------------------------------------
HOSTNAME="${1:-}"
DRY_RUN=false
RESTOW=false
DELETE=false
RESTORE=false

# Parse options
shift || true
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --restow)
            RESTOW=true
            shift
            ;;
        --delete)
            DELETE=true
            shift
            ;;
        --restore)
            RESTORE=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$HOSTNAME" ]; then
    log_error "No hostname provided."
    echo ""
    echo "Usage: $0 <hostname> [options]"
    echo ""
    echo "Example: $0 keith-macbook-pro"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be done without making changes"
    echo "  --restow     Remove and re-create symlinks (useful for updates)"
    echo "  --delete     Remove symlinks (unstow)"
    echo "  --restore    Restore dotfiles from a backup"
    echo ""
    
    # Determine the git repo root directory
    REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "")
    
    if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/hosts" ]; then
        echo "Available hosts:"
        ls -1 "$REPO_ROOT/hosts" | sed 's/^/  - /'
    fi
    
    exit 1
fi

log_info "Deploying dotfiles for host: $HOSTNAME"

# Determine the git repo root directory
REPO_ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel 2>/dev/null || echo "")

if [ -z "$REPO_ROOT" ]; then
    log_error "This script must be run from within a git repository."
    exit 1
fi

log_info "Repository root: $REPO_ROOT"

# Check if host directory exists
HOST_DIR="$REPO_ROOT/hosts/$HOSTNAME"

if [ ! -d "$HOST_DIR" ]; then
    log_error "Host directory not found: $HOST_DIR"
    echo ""
    echo "Available hosts:"
    ls -1 "$REPO_ROOT/hosts" | sed 's/^/  - /'
    exit 1
fi

log_success "Found host directory: $HOST_DIR"

# Define paths
GENERATED_DIR="$HOST_DIR/generated"
DOTFILES_DIR="$GENERATED_DIR/dotfiles"

# ------------------------------------------------------------------------
# Step 1: Validate Prerequisites
# ------------------------------------------------------------------------
log_info "Validating prerequisites..."

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    log_error "GNU Stow is not installed."
    echo ""
    echo "Please install GNU Stow first. You can do this by:"
    echo "  1. Running the bootstrap script: ./bootstrap-scripts/macos-arm64/bootstrap.sh"
    echo "  2. Or installing manually: nix-env -iA nixpkgs.stow"
    exit 1
fi

# Skip dotfiles validation in restore mode
if [ "$RESTORE" = false ]; then
    # Check if generated dotfiles directory exists
    if [ ! -d "$DOTFILES_DIR" ]; then
        log_error "Generated dotfiles directory not found: $DOTFILES_DIR"
        echo ""
        echo "Please run generate-config.sh first:"
        echo "  ./bootstrap-scripts/macos-arm64/generate-config.sh $HOSTNAME"
        exit 1
    fi

    # Check if dotfiles directory has any files
    if [ -z "$(find "$DOTFILES_DIR" -type f)" ]; then
        log_warning "No dotfiles found in: $DOTFILES_DIR"
        echo ""
        echo "The dotfiles directory is empty. Nothing to deploy."
        exit 0
    fi
fi

log_success "All prerequisites validated."

# ------------------------------------------------------------------------
# Handle Restore Operation
# ------------------------------------------------------------------------
if [ "$RESTORE" = true ]; then
    log_info "Restore mode: Looking for backup directories..."
    
    # Find all backup directories
    BACKUP_DIRS=()
    if [ -d "$GENERATED_DIR" ]; then
        while IFS= read -r backup_dir; do
            BACKUP_DIRS+=("$backup_dir")
        done < <(find "$GENERATED_DIR" -maxdepth 1 -type d -name "dotfiles-backup-*" | sort -r)
    fi
    
    if [ ${#BACKUP_DIRS[@]} -eq 0 ]; then
        log_error "No backup directories found in: $GENERATED_DIR"
        echo ""
        echo "Backups are created automatically when you deploy dotfiles."
        echo "If you need to restore, you must have a previous backup."
        exit 1
    fi
    
    log_info "Found ${#BACKUP_DIRS[@]} backup(s):"
    echo ""
    
    # Display available backups
    for i in "${!BACKUP_DIRS[@]}"; do
        BACKUP_NAME=$(basename "${BACKUP_DIRS[$i]}")
        BACKUP_DATE=$(echo "$BACKUP_NAME" | sed 's/dotfiles-backup-//')
        FILE_COUNT=$(find "${BACKUP_DIRS[$i]}" -type f | wc -l | tr -d ' ')
        echo "  [$((i+1))] $BACKUP_DATE ($FILE_COUNT files)"
    done
    
    echo ""
    echo -n "Select backup to restore (1-${#BACKUP_DIRS[@]}), or 'q' to quit: "
    read -r selection
    
    if [ "$selection" = "q" ] || [ "$selection" = "Q" ]; then
        log_info "Restore cancelled."
        exit 0
    fi
    
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#BACKUP_DIRS[@]} ]; then
        log_error "Invalid selection: $selection"
        exit 1
    fi
    
    SELECTED_BACKUP="${BACKUP_DIRS[$((selection-1))]}"
    log_info "Selected backup: $(basename "$SELECTED_BACKUP")"
    
    # Unstow current dotfiles first
    log_info "Removing current dotfile symlinks..."
    cd "$DOTFILES_DIR"
    if stow --verbose=2 --target="$HOME" --dir="$DOTFILES_DIR" --delete --no-folding . 2>/dev/null; then
        log_success "Removed existing symlinks."
    else
        log_warning "Some symlinks may not exist (this is normal if not previously stowed)."
    fi
    
    # Restore backed up files
    log_info "Restoring dotfiles from backup..."
    
    RESTORED_COUNT=0
    while IFS= read -r backup_file; do
        RELATIVE_PATH="${backup_file#$SELECTED_BACKUP/}"
        TARGET_FILE="$HOME/$RELATIVE_PATH"
        
        # Create target directory if needed
        mkdir -p "$(dirname "$TARGET_FILE")"
        
        # Copy backed up file to home
        cp -a "$backup_file" "$TARGET_FILE"
        RESTORED_COUNT=$((RESTORED_COUNT + 1))
        echo "  ✓ Restored: $RELATIVE_PATH"
    done < <(find "$SELECTED_BACKUP" -type f)
    
    echo ""
    log_success "=========================================="
    log_success "Restore Complete!"
    log_success "=========================================="
    echo ""
    log_info "Restored $RESTORED_COUNT file(s) from backup."
    log_info "Your dotfiles have been restored to their state before Stow deployment."
    
    exit 0
fi

# ------------------------------------------------------------------------
# Step 2: Backup Existing Dotfiles
# ------------------------------------------------------------------------
if [ "$DELETE" = false ]; then
    log_info "Checking for existing dotfiles that would be replaced..."
    
    BACKUP_DIR="$GENERATED_DIR/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
    NEEDS_BACKUP=false
    
    # Find all files in dotfiles directory and check if they exist in home
    while IFS= read -r dotfile; do
        # Get relative path from dotfiles directory
        RELATIVE_PATH="${dotfile#$DOTFILES_DIR/}"
        TARGET_FILE="$HOME/$RELATIVE_PATH"
        
        # Check if target exists and is not already a symlink to our generated dotfile
        if [ -e "$TARGET_FILE" ] && [ ! -L "$TARGET_FILE" ]; then
            if [ "$NEEDS_BACKUP" = false ]; then
                log_info "Found existing dotfiles that will be backed up:"
                NEEDS_BACKUP=true
            fi
            echo "  - $RELATIVE_PATH"
        fi
    done < <(find "$DOTFILES_DIR" -type f)
    
    if [ "$NEEDS_BACKUP" = true ]; then
        if [ "$DRY_RUN" = false ]; then
            log_info "Creating backup directory: $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            
            # Backup and remove existing files
            while IFS= read -r dotfile; do
                RELATIVE_PATH="${dotfile#$DOTFILES_DIR/}"
                TARGET_FILE="$HOME/$RELATIVE_PATH"
                
                if [ -e "$TARGET_FILE" ] && [ ! -L "$TARGET_FILE" ]; then
                    BACKUP_FILE="$BACKUP_DIR/$RELATIVE_PATH"
                    mkdir -p "$(dirname "$BACKUP_FILE")"
                    cp -a "$TARGET_FILE" "$BACKUP_FILE"
                    rm -f "$TARGET_FILE"
                fi
            done < <(find "$DOTFILES_DIR" -type f)
            
            log_success "Existing dotfiles backed up and removed to make way for symlinks."
            log_info "Backups saved to: $BACKUP_DIR"
        else
            log_info "[DRY RUN] Would backup and remove existing dotfiles."
            log_info "[DRY RUN] Backup location: $BACKUP_DIR"
        fi
    else
        log_info "No existing dotfiles need to be backed up."
    fi
fi

# ------------------------------------------------------------------------
# Step 3: Deploy with GNU Stow
# ------------------------------------------------------------------------
if [ "$DELETE" = true ]; then
    log_info "Removing dotfile symlinks (unstow)..."
    STOW_ACTION="--delete"
    ACTION_DESC="unstowed"
elif [ "$RESTOW" = true ]; then
    log_info "Re-creating dotfile symlinks (restow)..."
    STOW_ACTION="--restow"
    ACTION_DESC="restowed"
else
    log_info "Creating dotfile symlinks (stow)..."
    STOW_ACTION="--stow"
    ACTION_DESC="stowed"
fi

# Build stow command
STOW_CMD="stow"
STOW_CMD="$STOW_CMD --verbose=2"          # Show what's being done
STOW_CMD="$STOW_CMD --target=$HOME"       # Target is home directory
STOW_CMD="$STOW_CMD --dir=$DOTFILES_DIR"  # Source directory
STOW_CMD="$STOW_CMD $STOW_ACTION"         # Action (stow/restow/delete)
STOW_CMD="$STOW_CMD --no-folding"         # Don't fold directories into symlinks

if [ "$DRY_RUN" = true ]; then
    STOW_CMD="$STOW_CMD --simulate"
    log_info "[DRY RUN] Command: $STOW_CMD ."
fi

# GNU Stow expects package directories in the stow directory
# Our structure is: dotfiles/.gitconfig, dotfiles/.config/nix/nix.conf, etc.
# We need to stow "." to deploy all files
cd "$DOTFILES_DIR"

if $DRY_RUN; then
    log_warning "DRY RUN MODE - No changes will be made"
    echo ""
fi

# Execute stow
if eval "$STOW_CMD ."; then
    if [ "$DRY_RUN" = false ]; then
        log_success "Dotfiles successfully $ACTION_DESC!"
    else
        log_success "Dry run complete - no errors detected."
    fi
else
    log_error "Stow command failed."
    echo ""
    echo "This usually happens when:"
    echo "  - Files already exist and aren't symlinks (check backup directory)"
    echo "  - Directory structure conflicts (check Stow output above)"
    echo ""
    echo "You can try:"
    echo "  - Use --restow to re-create existing symlinks"
    echo "  - Manually remove conflicting files"
    echo "  - Check the backup directory: $BACKUP_DIR"
    exit 1
fi

# ------------------------------------------------------------------------
# Step 4: Display Summary
# ------------------------------------------------------------------------
echo ""
log_success "=========================================="
log_success "Deployment Complete!"
log_success "=========================================="
echo ""

if [ "$DELETE" = false ]; then
    log_info "Your dotfiles are now symlinked from:"
    log_info "  $DOTFILES_DIR"
    log_info ""
    log_info "To your home directory:"
    log_info "  $HOME"
    
    if [ "$NEEDS_BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
        echo ""
        log_info "Original files backed up to:"
        log_info "  $BACKUP_DIR"
    fi
    
    echo ""
    log_info "Deployed dotfiles:"
    find "$DOTFILES_DIR" -type f | while read -r file; do
        RELATIVE_PATH="${file#$DOTFILES_DIR/}"
        echo "  • $RELATIVE_PATH -> $HOME/$RELATIVE_PATH"
    done
else
    log_info "Dotfile symlinks have been removed."
fi

echo ""
log_info "To update dotfiles:"
log_info "  1. Modify source files in apps/*/  "
log_info "  2. Run: ./bootstrap-scripts/macos-arm64/generate-config.sh $HOSTNAME"
log_info "  3. Run: ./bootstrap-scripts/macos-arm64/deploy-dotfiles.sh $HOSTNAME --restow"

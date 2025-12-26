#!/bin/bash

# ========================================================================
# Script Helpers
# ========================================================================
# Shared helper functions for consistent script output across all scripts
# 
# Usage: Source this file at the beginning of your script:
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   source "${SCRIPT_DIR}/script-helpers.sh"
#   # OR for scripts in subdirectories:
#   source "${SCRIPT_DIR}/../.devcontainer/scripts/script-helpers.sh"
# ========================================================================

# Color definitions
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# ========================================================================
# Logging Functions
# ========================================================================

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

# ========================================================================
# Header/Footer Functions
# ========================================================================

# Display a script header with name and description
# Usage: script_header "Script Name" "Brief description of what this script does"
script_header() {
    local script_name="${1}"
    local description="${2}"
    
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║${NC}  ${BOLD}${script_name}${NC}"
    echo -e "${CYAN}${BOLD}╠════════════════════════════════════════════════════════════════════╣${NC}"
    if [ -n "${description}" ]; then
        echo -e "${CYAN}${BOLD}║${NC}  ${description}"
    fi
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Display a script footer indicating completion
# Usage: script_footer "success|warning|error" "Optional message"
script_footer() {
    local status="${1:-success}"
    local message="${2}"
    
    echo ""
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════╗${NC}"
    
    case "${status}" in
        success)
            echo -e "${CYAN}${BOLD}║${NC}  ${GREEN}${BOLD}✓ Script completed successfully${NC}"
            ;;
        warning)
            echo -e "${CYAN}${BOLD}║${NC}  ${YELLOW}${BOLD}⚠ Script completed with warnings${NC}"
            ;;
        error)
            echo -e "${CYAN}${BOLD}║${NC}  ${RED}${BOLD}✗ Script failed${NC}"
            ;;
    esac
    
    if [ -n "${message}" ]; then
        echo -e "${CYAN}${BOLD}║${NC}  ${message}"
    fi
    
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

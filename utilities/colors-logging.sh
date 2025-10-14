#!/usr/bin/env bash

#
# Colors and Logging Utilities
#
# This file contains utility functions for setting up colors and providing
# consistent logging functionality across the Dev Magic application.
#

# Initialize color variables
declare -g NOFORMAT
declare -g RED
declare -g GREEN
declare -g ORANGE
declare -g BLUE
declare -g PURPLE
declare -g CYAN
declare -g YELLOW
declare -g BOLD
declare -g NORMAL

# Setup colors for terminal output
devmagic_setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' 
    RED='\033[0;31m' 
    GREEN='\033[0;32m' 
    ORANGE='\033[0;33m' 
    BLUE='\033[0;34m' 
    PURPLE='\033[0;35m' 
    CYAN='\033[0;36m' 
    YELLOW='\033[1;33m'

    # Text styles
    BOLD=$(tput bold)
    NORMAL=$(tput sgr0)
  else
    NOFORMAT='' 
    RED='' 
    GREEN='' 
    ORANGE='' 
    BLUE='' 
    PURPLE='' 
    CYAN='' 
    YELLOW=''
    
    # Text styles
    BOLD=''
    NORMAL=''
  fi

  # Export colors so they're available in subshells
  export NOFORMAT RED GREEN ORANGE BLUE PURPLE CYAN YELLOW BOLD NORMAL
}

# General message function
devmagic_msg() {
  echo >&2 -e "${1-}"
}

# Log information message (blue)
devmagic_log_info() {
  devmagic_msg "${BLUE}[INFO]${NOFORMAT} $1"
}

# Log success message (green)
devmagic_log_success() {
  devmagic_msg "${GREEN}[SUCCESS]${NOFORMAT} $1"
}

# Log warning message (yellow/orange)
devmagic_log_warning() {
  devmagic_msg "${YELLOW}[WARNING]${NOFORMAT} $1"
}

# Log error message (red)
devmagic_log_error() {
  devmagic_msg "${RED}[ERROR]${NOFORMAT} $1"
}

# Log debug message (only shown when debug mode is enabled)
devmagic_log_debug() {
  if [[ "${DEVMAGIC_DEBUG:-0}" == "1" ]]; then
    devmagic_msg "${PURPLE}[DEBUG]${NOFORMAT} $1"
  fi
}

# Display a section header
devmagic_section_header() {
  local title="$1"
  local padding_char="${2:-#}"
  local line=$(printf '%*s' 60 | tr ' ' "$padding_char")
  local title_length=${#title}
  local padding_after=$((60 - title_length - 4)) # Calculate padding after title (4 = space + padding_char + space on each side)
  local padding_spaces=$(printf '%*s' $padding_after | tr ' ' ' ')

  echo -e "${GREEN}${line}${NOFORMAT}"
  echo -e "${GREEN}${padding_char} ${BOLD}${title}${NORMAL}${GREEN} ${padding_spaces}${padding_char}${NOFORMAT}"
  echo -e "${GREEN}${line}${NOFORMAT}"
}

# Initialize colors when this script is sourced
devmagic_setup_colors

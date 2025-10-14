#!/bin/bash
#
# Config management for Dev Magic

# The devmagic config path
DEVMAGIC_CONFIG="/etc/default/devmagic.conf"

# Default config values array.
declare -A -g devmagic_config_defaults

# Set default values in config array.
devmagic_config_defaults=(
  # Set the CERT variables for both mkcert and mkcertissuer.
  [COUNTRY]="BG"
  [STATE]="Sofia"
  [ORG]="Web Timeless Ltd."
  [ORG_UNIT]="PL"
  [COMMON_NAME]="Web Timeless Ltd."
  [EMAIL]="support@webtimeless.bg"
  [PASS]="875421"
  [ROOT_CERT_NAME]="LocalhostCA"
)

export devmagic_config_defaults

# Init array.
declare -A -g devmagic_config

# Set default user values in config array.
devmagic_config=(
  # Set global CERT paths.
  [CERTS_DIR]="/etc/ssl/localcerts"
  [CERTS_ISSUER_DIR]="/etc/ssl/localcerts/cert-issuer"

  # Set the WEB variables.
  [WEB_DIR]="/var/www"
  [APACHE_SITES_AVAILABLE]="/etc/apache2/sites-available"

  # Set the WP database variables.
  [WP_DB_PREFIX]="wp_"
  [WP_DB_USER]="root"
  [WP_DB_PASSWORD]="Root123@"
  [WP_DB_HOST]="localhost"

  # Set WP User variables.
  [WP_ADMIN_USER]="admin"
  [WP_ADMIN_PASSWORD]="admin"
)

#######################################
# Function to read configuration from file and populate the config array
# devmagic_conf_read_file()
# 
# Reads configuration from the DEVMAGIC_CONFIG file into the 
# devmagic_config associative array.
#
# Parameters:
#   None
#
# Globals:
#   DEVMAGIC_CONFIG - Path to the configuration file (read)
#   devmagic_config - Associative array to store configuration (write)
#
# Returns:
#   0 - If configuration file was successfully read
#   1 - If configuration file does not exist
#
# Example:
#   devmagic_conf_read_file || echo "Config file not found"
#######################################
devmagic_conf_read_file() {
  # Check if the config file exists
  if [[ ! -e "${DEVMAGIC_CONFIG}" ]]; then
    return 1
  fi

  # Read the config file line by line
  while read -r line
  do
    if echo "$line" | grep -F = &>/dev/null
    then
      varname=$(echo "$line" | cut -d '=' -f 1)
      value=$(echo "$line" | cut -d '=' -f 2- | sed 's/^"//;s/"$//')
      # Update the config array with values from config file
      devmagic_config[$varname]="$value"
    fi
  done < $DEVMAGIC_CONFIG

  return 0
}

#######################################
# Function: devmagic_conf_print
# Description: Prints all key-value pairs from the devmagic_config associative array
#
# Usage: devmagic_conf_print
#
# Arguments: None
#
# Returns: None
#
# Output: Prints each configuration key and its corresponding value in the format:
#         key=value
#
# Dependencies: Requires devmagic_config associative array to be declared and populated
#
# Example:
#   devmagic_conf_print
#   # Output might be:
#   # WEB_DIR=/var/www
#   # CERTS_DIR=/etc/ssl/localcerts
#######################################
devmagic_conf_print() {
  for key in "${!devmagic_config[@]}"; do echo "${key}"="${devmagic_config[${key}]}"; done
}

#######################################
# Function: devmagic_conf_set
#
# Description:
#   Adds or updates a configuration key-value pair in the DEVMAGIC_CONFIG file.
#   The function requires root privileges to modify the configuration file.
#
# Parameters:
#   $1 - key: The configuration key to set
#   $2 - value: The value to assign to the key
#
# Global Variables:
#   DEVMAGIC_CONFIG: The path to the configuration file
#
# Returns:
#   None
#
# Exit Status:
#   0: Success
#   Non-zero: Displays an error message if key or value parameters are missing
#
# Usage:
#   devmagic_conf_set "key_name" "value"
#
# Notes:
#   - Uses sudo to write to the configuration file
#   - Appends to the configuration file rather than modifying existing entries
#   - Values are properly quoted in the configuration file
#######################################
devmagic_conf_set() {
  local key="$1"
  local value="$2"

  # Verifying that the key and value are passed correctly
  if [[ -n "$key" && -n "$value" ]]; then
    # Set the config variable
    echo "${key}=\"${value}\"" | sudo tee --append "$DEVMAGIC_CONFIG" > /dev/null
  else
    printf "Error: Missing key or value in %s\\n" "${FUNCNAME[0]}"
  fi
}

#######################################
# Function: devmagic_conf_wizard
# Description: Interactive configuration wizard for Dev Magic that guides the user
#              through setting up configuration options.
#
# The wizard performs the following operations:
# 1. Displays a welcome message with instructions
# 2. Loads existing configuration if available, or creates a new config file
# 3. Prompts the user for each configuration option, showing current/default values
# 4. Saves all configuration settings to the config file
#
# Dependencies:
# - devmagic_section_header: Function to display formatted section headers
# - devmagic_conf_read_file: Function to read the existing configuration file
# - devmagic_conf_set: Function to write key-value pairs to the config file
#
# Global variables used:
# - DEVMAGIC_CONFIG: Path to the configuration file
# - devmagic_config: Associative array holding configuration key-value pairs
# - Color variables: PURPLE, BLUE, YELLOW, ORANGE, CYAN, GREEN, BOLD, NORMAL, NOFORMAT
#
# Returns:
#   0 on successful completion
#######################################
devmagic_conf_wizard() {
  # Colors loaded from utilities

  # Welcome message
  devmagic_section_header "Dev Magic Configuration Wizard 🪄"
  echo
  echo -e "${PURPLE}We'll help you configure Dev Magic with your preferred settings.${NOFORMAT}"
  echo -e "${BLUE}Press Enter to keep the default value shown in brackets.${NOFORMAT}"
  echo

  # First, load existing configuration if it exists
  if devmagic_conf_read_file; then
    echo -e "${YELLOW}Loading existing configuration from ${DEVMAGIC_CONFIG}${NOFORMAT}"
  else
    # Create the file if it does not exist
    echo -e "${YELLOW}Creating new configuration file at ${DEVMAGIC_CONFIG}${NOFORMAT}"
    sudo touch $DEVMAGIC_CONFIG
  fi

  # Go through each config option and ask for input
  for key in "${!devmagic_config[@]}"; do
    local default_value="${devmagic_config[${key}]}"
    local user_value=""

    # Ask user for input, showing the default value
    read -r -p "$(echo -e "${ORANGE}Enter ${CYAN}${key}${ORANGE} [${BOLD}${default_value}${NORMAL}${ORANGE}]: ${NOFORMAT}")" user_value

    # If user didn't input anything, use the default value
    if [[ -z "$user_value" ]]; then
      user_value="$default_value"
    fi

    # Update the config array with the new value
    devmagic_config[${key}]="${user_value}"
  done

  echo -e "${GREEN}Configuration completed successfully!${NOFORMAT}"

  # Write all settings to config file
  # First, clear the file to avoid duplicates
  sudo truncate -s 0 $DEVMAGIC_CONFIG

  # Now write all settings
  for key in "${!devmagic_config[@]}"; do
    devmagic_conf_set "${key}" "${devmagic_config[${key}]}"
  done

  echo -e "${BLUE}Configuration saved to ${DEVMAGIC_CONFIG}${NOFORMAT}"
}

#######################################
# Function: devmagic_conf_mk
#
# Description:
#   Ensures the DEVMAGIC_CONFIG file exists and initializes it with default
#   configuration values. If the configuration file does not exist, it is
#   created with sudo privileges. Then, for each key-value pair in the
#   devmagic_config associative array, the devmagic_conf_set function is called
#   to set the configuration.
#
# Globals:
#   DEVMAGIC_CONFIG      - Path to the configuration file.
#   devmagic_config      - Associative array containing default config values.
#
# Arguments:
#   None
#
# Returns:
#   None
#
# Example:
#   devmagic_conf_mk
#######################################
devmagic_conf_mk() {

  # Create the file if it does not exist.
  if [[ ! -e "${DEVMAGIC_CONFIG}" ]]
  then
    sudo touch $DEVMAGIC_CONFIG
  fi

  # Set the default configs.
  for key in "${!devmagic_config[@]}"
  do
    devmagic_conf_set "${key}" "${devmagic_config[${key}]}"
  done
}

#######################################
# Function: devmagic_conf_load
# Description: Loads configuration for devmagic by either initializing a new configuration
#              through a wizard or loading an existing configuration file.
# Parameters: none
# Returns: none
# Dependencies: DEVMAGIC_CONFIG (global variable), devmagic_conf_wizard, devmagic_conf_read_file
# Example usage: devmagic_conf_load
#######################################
devmagic_conf_load() {

  # Initialize config if it's missing.
  if [[ ! -e "${DEVMAGIC_CONFIG}" ]]
  then
    # Instead of just creating a default config, run the wizard
    echo -e "No configuration file found. Starting configuration wizard..."
    devmagic_conf_wizard
  else
    # Load existing config using the extracted function
    devmagic_conf_read_file
  fi
}

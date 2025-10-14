#!/usr/bin/env bash
#
# WordPress setup script

#######################################
# Function: setup_wp_config_local
# Description: Sets up WordPress configuration by creating wp-config.php from a sample file
#              and updating database settings using WP-CLI.
# 
# Arguments:
#   $1 - wp_path: Path to WordPress installation directory
#   $2 - dbname: Database name
#   $3 - dbuser: Database username
#   $4 - dbpass: Database password
#   $5 - dbprefix: Database table prefix (optional)
#
# Returns:
#   0 on success
#   1 on failure (WordPress directory not found, sample config not found, WP-CLI missing)
#
# Dependencies:
#   - WP-CLI must be installed and available in PATH
#   - devmagic_log_error, devmagic_log_warning, devmagic_log_info, devmagic_msg functions
#
# Example usage:
#   setup_wp_config_local "/var/www/html" "wordpress_db" "wp_user" "password" "wp_"
#######################################
setup_wp_config_local() {
  local wp_path=$1
  local dbname=$2
  local dbuser=$3
  local dbpass=$4
  local dbprefix=$5

  if [[ ! -d "${wp_path}" ]]; then
    devmagic_log_error "WordPress directory not found: ${wp_path}"
    return 1
  fi

  # Look for wp-config-local-sample.php
  local config_sample=""

  # Check root folder for wp-config-local-sample.php
  if [[ -f "${wp_path}/wp-config-local-sample.php" ]]; then
    config_sample="${wp_path}/wp-config-local-sample.php"
  fi

  if [[ -z "${config_sample}" ]]; then
    devmagic_log_warning "No wp-config-local-sample.php found, skipping configuration."
    return 1
  fi

  devmagic_msg "${BLUE}Found sample config file: ${GREEN}${config_sample}${NOFORMAT}"

  # Copy sample to wp-config.php if it doesn't exist
  if [[ ! -f "${wp_path}/wp-config.php" ]]; then
    devmagic_msg "${BLUE}Creating wp-config.php from sample...${NOFORMAT}"
    cp "${config_sample}" "${wp_path}/wp-config.php"
    
    # Update database settings
    if command -v wp &> /dev/null; then
      cd "${wp_path}" || return 1
      devmagic_msg "${BLUE}Updating database configuration...${NOFORMAT}"
      wp config set DB_NAME "${dbname}" --type=constant
      wp config set DB_USER "${dbuser}" --type=constant
      wp config set DB_PASSWORD "${dbpass}" --type=constant

      # Set custom table prefix if provided and not in wp-config.php yet
      if [[ -n "${dbprefix}" && ! $(wp config get table_prefix --type=variable) ]]; then
        wp config set table_prefix "${dbprefix}" --type=variable
      fi

      # Generate WordPress salts
      devmagic_msg "${BLUE}Generating WordPress salts...${NOFORMAT}"
      wp config shuffle-salts

      return $?
    else
      devmagic_log_warning "WP-CLI not found. Manual configuration of wp-config.php required."
      return 1
    fi
  else
    devmagic_log_info "wp-config.php already exists, keeping existing configuration."
    return 0
  fi
}

#######################################
# WordPress Website Creation Function
#
# This function sets up a WordPress website with optional repository cloning
# and database import capabilities.
#
# Usage:
#   mkwpwebsite
#
# Required Global Variables:
#   domain - Domain name for the WordPress site
#   dbname - Database name
#   dbuser - Database user
#   dbpass - Database password
#   dbprefix - Database table prefix
#   title - Website title
#   admin_user - WordPress admin username
#   admin_password - WordPress admin password
#   admin_email - WordPress admin email
#
# Optional Global Variables:
#   content_repo - Git repository URL to clone (if repository-based setup)
#   dbfile - Path to database file to import (if importing existing database)
#
# Dependencies:
#   - WP-CLI must be installed and available in PATH
#   - devmagic_config array with WEB_DIR defined
#   - Support functions: devmagic_log_info, devmagic_log_warning, is_dir, is_file, clone_to_domain, setup_wp_config_local
#
# Returns:
#   0 on success, 1 on failure
#######################################
mkwpwebsite() {

  WITH_FILE=0
  WITH_REPO=0

  if [[ -n "${dbfile}" ]]; then
    WITH_FILE=1
  fi

  if [[ -n "${content_repo}" ]]; then
    WITH_REPO=1
  fi

  WEB_DIR="${devmagic_config[WEB_DIR]}"
  DOMAIN_DIR="${WEB_DIR}/${domain}"

  # Create domain directory if it doesn't exist
  if [[ 0 == $( ( is_dir "${DOMAIN_DIR}" ) && printf "1" || printf "0" ) ]]; then
    sudo mkdir -p "${DOMAIN_DIR}"
    sudo chmod 777 -R "${DOMAIN_DIR}"
  fi

  # First step: Clone repository if specified
  if [[ 1 == "${WITH_REPO}" ]]; then
    devmagic_log_info "${CYAN}Cloning project repository to ${DOMAIN_DIR}...${NOFORMAT}"
    clone_to_domain "${content_repo}" "${DOMAIN_DIR}"

    # Check for wp-config-local-sample.php and set it up
    cd "${DOMAIN_DIR}" || return 1
    if setup_wp_config_local "${DOMAIN_DIR}" "${dbname}" "${dbuser}" "${dbpass}" "${dbprefix}"; then
      devmagic_log_info "${CYAN}WordPress config successfully set up from template${NOFORMAT}"

      # Check if WordPress core files exist
      if [[ ! -f "${DOMAIN_DIR}/wp-load.php" ]]; then
        devmagic_log_info "${CYAN}WordPress core files not found, downloading WordPress...${NOFORMAT}"
        wp core download --skip-content --force || true
      fi

      # Create the database
      devmagic_log_info "${CYAN}Create the database...${NOFORMAT}"
      wp db create || true

      # Check if WordPress is already installed by checking if tables exist
      if wp db tables --all-tables-with-prefix --format=count 2>/dev/null | grep -q '[1-9]'; then
        devmagic_log_info "${CYAN}WordPress tables already exist, skipping installation${NOFORMAT}"
      else
        # Install WordPress
        devmagic_log_info "${CYAN}Install WordPress...${NOFORMAT}"
        wp core install --url="${domain}" --title="${title}" --admin_user="${admin_user}" --admin_password="${admin_password}" --admin_email="${admin_email}" --skip-email || true
      fi
    else
      devmagic_log_warning "${YELLOW}Could not set up WordPress config from template${NOFORMAT}"

      # Check if WordPress core files exist
      if [[ ! -f "${DOMAIN_DIR}/wp-load.php" ]]; then
        devmagic_log_info "${CYAN}WordPress core files not found, downloading WordPress...${NOFORMAT}"
        wp core download --skip-content --force || true
      fi

      # Generate a config file
      devmagic_log_info "${CYAN}Generate a wp-config.php file...${NOFORMAT}"
      wp config create --dbname="${dbname}" --dbuser="${dbuser}" --dbpass="${dbpass}" --dbprefix="${dbprefix}" || true

      # Create the database
      devmagic_log_info "${CYAN}Create the database...${NOFORMAT}"
      wp db create || true

      # Install WordPress
      devmagic_log_info "${CYAN}Install WordPress...${NOFORMAT}"
      wp core install --url="${domain}" --title="${title}" --admin_user="${admin_user}" --admin_password="${admin_password}" --admin_email="${admin_email}" --skip-email || true
    fi
  else
    # Standard WordPress installation
    cd "${DOMAIN_DIR}" || return 1
    devmagic_log_info "${CYAN}Download WordPress...${NOFORMAT}"
    wp core download || true

    # Generate a config file
    devmagic_log_info "${CYAN}Generate a wp-config.php file...${NOFORMAT}"
    wp config create --dbname="${dbname}" --dbuser="${dbuser}" --dbpass="${dbpass}" --dbprefix="${dbprefix}" || true

    # Create the database
    devmagic_log_info "${CYAN}Create the database...${NOFORMAT}"
    wp db create || true

    # Install WordPress
    devmagic_log_info "${CYAN}Install WordPress...${NOFORMAT}"
    wp core install --url="${domain}" --title="${title}" --admin_user="${admin_user}" --admin_password="${admin_password}" --admin_email="${admin_email}" --skip-email || true
  fi

  # Import database if specified
  if [[ 1 == "${WITH_FILE}" && 1 == $( ( is_file "${dbfile}" ) && printf "1" || printf "0" ) ]]; then
    devmagic_log_info "${CYAN}Reset DB...${NOFORMAT}"
    wp db reset --yes # Add --yes to skip confirmation

    devmagic_log_info "${CYAN}Import DB ${GREEN}${dbfile}${CYAN}...${NOFORMAT}"
    wp db import "${dbfile}"

    siteurl=$(wp option get siteurl)
    sitedomain=$(echo "$siteurl" | awk -F[/:] '{print $4}')

    # Check if the domain and site domain are not the same. If they are, skip the search & replace.
    if [[ "${domain}" == "${sitedomain}" ]]; then
      devmagic_log_info "${YELLOW}Domain and site domain are the same (${domain}), skipping search & replace.${NOFORMAT}"
    # If not, do the search & replace.
    else
      devmagic_log_info "${CYAN}Search & Replace ${RED}${sitedomain} ${CYAN}-> ${GREEN}${domain}${CYAN}...${NOFORMAT}"
      wp search-replace "${sitedomain}" "${domain}" --all-tables --precise;
    fi

    # Install the local env-specific plugins.
    devmagic_log_info "${CYAN}Install & activate the local env-specific plugins ${CYAN}-> ${GREEN}query-monitor, be-media-from-production${CYAN}...${NOFORMAT}"
    wp plugin install query-monitor be-media-from-production --activate

    # Set variable to the wp-config.php file with the URL for media.
    devmagic_log_info "${CYAN}Set variable to the wp-config.php ${GREEN}BE_MEDIA_FROM_PRODUCTION_URL ${CYAN}-> ${GREEN}${siteurl}${CYAN}...${NOFORMAT}"
    wp config set BE_MEDIA_FROM_PRODUCTION_URL "${siteurl}"
  fi
}

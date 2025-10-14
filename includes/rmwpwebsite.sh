#!/usr/bin/env bash

# Function to remove WordPress site
rmwpwebsite() {
  local domain="${1}"
  local WEB_DIR="${devmagic_config[WEB_DIR]}"
  local wp_dir="${WEB_DIR}/${domain}"
  local db_name=""
  local db_user=""
  local db_password=""

  # Check if directory exists
  if [[ ! -d "${wp_dir}" ]]; then
    devmagic_log_warning "Directory ${wp_dir} does not exist."
    return 1
  fi

  cd "${wp_dir}" || return 1

  # Check for wp-config.php file
  if [[ -f "${wp_dir}/wp-config.php" ]]; then
    devmagic_log_info "Found wp-config.php file."

    # Extract database info from wp-config.php
    db_name=$(grep DB_NAME "${wp_dir}/wp-config.php" | grep -o "'.*'" | sed "s/'//g" | head -1)
    db_user=$(grep DB_USER "${wp_dir}/wp-config.php" | grep -o "'.*'" | sed "s/'//g" | head -1)
    db_password=$(grep DB_PASSWORD "${wp_dir}/wp-config.php" | grep -o "'.*'" | sed "s/'//g" | head -1)

    devmagic_log_info "Database name found in config: ${db_name}"

    # Verify this is a WordPress site by checking if wp-cli works
    if wp core version &>/dev/null; then
      devmagic_log_info "WordPress installation verified with WP-CLI."

      # Try to get site URL without failing if database is broken
      local site_url
      site_url=$(wp option get siteurl 2>/dev/null || echo "")

      if [[ -n "${site_url}" ]]; then
        if [[ "${site_url}" != *"${domain}"* ]]; then
          devmagic_log_warning "Warning: Site URL (${site_url}) doesn't match the provided domain (${domain})."
          read -p "Continue anyway? (y/n): " -r continue_anyway
          if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            devmagic_log_info "Operation cancelled."
            return 1
          fi
        fi
      else
        devmagic_log_warning "Could not retrieve site URL. Database might be broken or missing."
      fi

      # Remove database using wp-cli
      devmagic_log_info "Attempting to remove WordPress database via WP-CLI..."
      if wp db drop --yes 2>/dev/null; then
        devmagic_log_success "Database removed successfully via WP-CLI."
      else
        devmagic_log_warning "Failed to remove database via WP-CLI. Trying direct MySQL approach..."
        # Try to remove database directly using MySQL if wp-cli fails
        if [[ -n "${db_name}" ]] && [[ -n "${db_user}" ]]; then
          devmagic_log_info "Attempting to remove database '${db_name}' directly via MySQL..."

          # Check if MySQL can connect with these credentials
          if mysql -u "${db_user}" -p"${db_password}" -e "use ${db_name}" 2>/dev/null; then
            # Database exists and credentials work
            if mysql -u "${db_user}" -p"${db_password}" -e "DROP DATABASE IF EXISTS ${db_name}" 2>/dev/null; then
              devmagic_log_success "Database '${db_name}' removed successfully via direct MySQL command."
            else
              devmagic_log_error "Failed to remove database '${db_name}' via direct MySQL command."
            fi
          else
            devmagic_log_warning "Could not connect to database '${db_name}' or database doesn't exist. Skipping database removal."
          fi
        else
          devmagic_log_warning "Could not determine database name or credentials from wp-config.php. Skipping database removal."
        fi
      fi
    else
      devmagic_log_warning "WP-CLI not working with this WordPress installation."
      # Try to remove database directly if we have the info
      if [[ -n "${db_name}" ]] && [[ -n "${db_user}" ]]; then
        devmagic_log_info "Attempting to remove database '${db_name}' directly via MySQL..."
        if mysql -u "${db_user}" -p"${db_password}" -e "DROP DATABASE IF EXISTS ${db_name}" 2>/dev/null; then
          devmagic_log_success "Database '${db_name}' removed successfully via direct MySQL command."
        else
          devmagic_log_warning "Failed to remove database '${db_name}' or it doesn't exist. Continuing with file cleanup."
        fi
      fi
    fi
  else
    devmagic_log_warning "No wp-config.php file found. Not a valid WordPress installation or configuration is missing."
  fi

  # Remove directory regardless of WordPress validation status
  devmagic_log_info "Removing website files from ${wp_dir}..."
  cd "${WEB_DIR}" || return 1
  if sudo rm -rf "${domain}"; then
    devmagic_log_success "Website files removed successfully."
  else
    devmagic_log_error "Failed to remove website files."
  fi

  return 0
}

# Function to remove Apache site configuration
rmapacheconfig() {
  local domain="${1}"
  local config_file="/etc/apache2/sites-available/${domain}-ssl.conf"

  # Check if config file exists
  if [[ ! -f "${config_file}" ]]; then
    devmagic_log_warning "Apache configuration ${config_file} does not exist."
    return 0
  fi

  # Disable site if enabled
  if [[ -f "/etc/apache2/sites-enabled/${domain}-ssl.conf" ]]; then
    devmagic_log_info "Disabling Apache site..."
    if sudo a2dissite "${domain}-ssl.conf"; then
      devmagic_log_success "Apache site disabled successfully."
    else
      devmagic_log_error "Failed to disable Apache site."
    fi
  fi

  # Remove configuration file
  devmagic_log_info "Removing Apache configuration file..."
  if sudo rm "${config_file}"; then
    devmagic_log_success "Apache configuration removed successfully."
  else
    devmagic_log_error "Failed to remove Apache configuration."
  fi

  # Reload Apache
  devmagic_log_info "Reloading Apache configuration..."
  if sudo systemctl reload apache2; then
    devmagic_log_success "Apache reloaded successfully."
  else
    devmagic_log_error "Failed to reload Apache."
  fi

  return 0
}

# Function to remove domain from hosts file
rmhostsentry() {
  local domain="${1}"

  devmagic_log_info "Removing ${domain} from /etc/hosts..."

  # Check if domain exists in hosts file using a more flexible pattern match
  if grep -q "[[:space:]]${domain}\([[:space:]]\|$\)" /etc/hosts; then
    # Remove domain from hosts file using a more flexible pattern to handle variable spacing
    if sudo sed -i -E "/127\.0\.0\.1[[:space:]]+${domain}([[:space:]]|$)/d" /etc/hosts; then
      devmagic_log_success "${domain} removed from /etc/hosts successfully."
    else
      devmagic_log_error "Failed to remove ${domain} from /etc/hosts."
    fi
  else
    devmagic_log_warning "${domain} not found in /etc/hosts."
  fi

  return 0
}

# Function to remove SSL certificates
rmcerts() {
  local domain="${1}"
  local certs_dir="/etc/ssl/localcerts/${domain}"

  # Check if certificates directory exists
  if [[ ! -d "${certs_dir}" ]]; then
    devmagic_log_warning "SSL certificates directory ${certs_dir} does not exist."
    return 0
  fi

  devmagic_log_info "Removing SSL certificates for ${domain}..."

  # Remove certificates directory
  if sudo rm -rf "${certs_dir}"; then
    devmagic_log_success "SSL certificates removed successfully."
  else
    devmagic_log_error "Failed to remove SSL certificates."
  fi

  return 0
}

# Main cleanup function that calls all the others
cleanup_site() {
  local domain="${1}"

  if [[ -z "${domain}" ]]; then
    devmagic_log_error "Domain is required for cleanup."
    return 1
  fi

  devmagic_log_info "Starting cleanup for ${domain}..."

  # Remove WordPress installation and database
  rmwpwebsite "${domain}"

  # Remove Apache configuration
  rmapacheconfig "${domain}"

  # Remove hosts entry
  rmhostsentry "${domain}"

  # Remove SSL certificates
  rmcerts "${domain}"

  devmagic_log_success "Cleanup for ${domain} completed!"
  return 0
}

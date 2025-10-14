#!/usr/bin/env bash

# Wizard function for cleaning up a WordPress site
rmwizard() {
  local domain=""
  local confirm=""
  
  devmagic_section_header "WordPress Site Cleanup Wizard 🧹"
  echo
  echo -e "${PURPLE}This wizard will help you clean up a WordPress site, including its files,${NOFORMAT}"
  echo -e "${BLUE}database, Apache configuration, SSL certificates, and hosts file entry.${NOFORMAT}"
  echo
  
  # Get domain name
  while [[ -z "${domain}" ]]; do
    read -p "Enter the domain name to clean up: " domain
    
    if [[ -z "${domain}" ]]; then
      devmagic_log_error "Domain name cannot be empty."
    fi
  done
  
  # Check if website directory exists
  if [[ ! -d "/var/www/${domain}" ]]; then
    devmagic_log_warning "Warning: Website directory /var/www/${domain} does not exist."
    read -p "Continue anyway? (y/n): " -r continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
      devmagic_log_info "Operation cancelled."
      return 1
    fi
  fi
  
  # Check if Apache config exists
  if [[ ! -f "/etc/apache2/sites-available/${domain}-ssl.conf" ]]; then
    devmagic_log_warning "Warning: Apache configuration for ${domain} does not exist."
  fi
  
  # Check if SSL certificates exist
  if [[ ! -d "/etc/ssl/localcerts/${domain}" ]]; then
    devmagic_log_warning "Warning: SSL certificates for ${domain} do not exist."
  fi
  
  # Confirmation
  devmagic_log_warning "WARNING: This will permanently delete:"
  devmagic_log_warning "  - WordPress files in /var/www/${domain}"
  devmagic_log_warning "  - WordPress database for ${domain}"
  devmagic_log_warning "  - Apache configuration for ${domain}"
  devmagic_log_warning "  - SSL certificates for ${domain}"
  devmagic_log_warning "  - Hosts file entry for ${domain}"
  
  read -p "Are you sure you want to proceed? (yes/no): " confirm
  
  if [[ "${confirm}" != "yes" ]]; then
    devmagic_log_info "Operation cancelled."
    return 1
  fi
  
  # Perform cleanup
  cleanup_site "${domain}"
  
  return $?
}

#!/usr/bin/env bash
#
# Generating a config ssl file for specific domain


mkconfig-ssl() {

  # Check if domain is provided
  if [ -z "$domain" ]; then
    devmagic_log_error "Domain is required. Please set the domain variable."
    return 1
  fi

  CONFIG_FILE_DIR="${devmagic_config[APACHE_SITES_AVAILABLE]}"
  CERTS_FILE_DIR=$(readlink -f "${devmagic_config[CERTS_DIR]}") # The full absolute path.

  cd "$CONFIG_FILE_DIR" || return 1

  # Generate config file
  sudo bash -c "cat > ${domain}-ssl.conf << 'EOF'
<VirtualHost *:80> 
  ServerName ${domain}
  ServerAlias www.${domain}

  Redirect permanent / https://${domain}/
</VirtualHost>
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName ${domain}
    ServerAlias www.${domain}
    DocumentRoot /var/www/${domain}
    <Directory /var/www/${domain}>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
        Require all granted
    </Directory>

    SSLEngine on
    SSLCertificateFile $CERTS_FILE_DIR/${domain}/${domain}.crt
    SSLCertificateKeyFile $CERTS_FILE_DIR/${domain}/${domain}.key
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF"

  # Activate config file
  # Check if site is already enabled
  if sudo a2ensite "${domain}"-ssl.conf 2>&1 | grep -q "already enabled"; then
    devmagic_log_info "Site ${domain}-ssl.conf is already enabled"
  else
    sudo a2ensite "${domain}"-ssl.conf
  fi

  # Test config Syntax
  if output=$(apachectl configtest 2>&1); then
    devmagic_log_info "Syntax OK"
    devmagic_log_success "The SSL config file for ${domain} has been created and enabled successfully!"
    # add the domain to /etc/hosts
    devmagic_log_info "Adding ${domain} to /etc/hosts ..."
    if ! grep -q "${domain}" /etc/hosts; then
      echo "127.0.0.1 ${domain}" | sudo tee -a /etc/hosts > /dev/null
      devmagic_log_success "Added ${domain} to /etc/hosts"
    else
      devmagic_log_info "${domain} already exists in /etc/hosts"
    fi
    # Reload Apache
    sudo systemctl reload apache2
  else
    devmagic_log_error "$output"
    exit 1
  fi
}

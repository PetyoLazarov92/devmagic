#!/bin/sh
#
# Generating the Private Key and Root Certificate

#######################################
# Function: mkcertissuer
#
# Description:
#   Creates and installs a self-signed root certificate authority (CA) for local development.
#   This function generates a new RSA key pair, creates a root certificate, and adds it to
#   the system's trusted CA store.
#
# Usage:
#   mkcertissuer
#
# Global Variables:
#   devmagic_config_defaults - Configuration defaults array for certificate details
#   devmagic_config - Configuration array containing certificate storage locations
#
# Variables Set:
#   COUNTRY - Country code for the certificate
#   STATE - State/Province for the certificate
#   ORG - Organization name for the certificate
#   ORG_UNIT - Organizational unit for the certificate
#   COMMON_NAME - Common name for the certificate
#   EMAIL - Email address for the certificate
#   CERTS_DIR - Directory where certificates will be stored
#   ROOT_CERT_NAME - Name of the root certificate
#   PASS - Password for the private key
#
# Returns:
#   0 - Success
#   1 - Failure (if directory change fails)
#
# Notes:
#   - Requires sudo privileges to create directories and install certificates
#   - Installs ca-certificates package if not already installed
#   - Verifies successful installation by searching for the certificate in the CA store
#######################################
mkcertissuer() {
  # Load configuration defaults
  #
  # Note: If you change the configuration defaults,
  # you may need to reissue any previously signed certificates with this CA.
  COUNTRY="${devmagic_config_defaults[COUNTRY]}"
  STATE="${devmagic_config_defaults[STATE]}"
  ORG="${devmagic_config_defaults[ORG]}"
  ORG_UNIT="${devmagic_config_defaults[ORG_UNIT]}"
  COMMON_NAME="${devmagic_config_defaults[COMMON_NAME]}"
  EMAIL="${devmagic_config_defaults[EMAIL]}"
  CERTS_DIR="${devmagic_config[CERTS_ISSUER_DIR]}"
  ROOT_CERT_NAME="${devmagic_config_defaults[ROOT_CERT_NAME]}"
  PASS="${devmagic_config_defaults[PASS]}"

  # Create certs directory
  devmagic_log_info "Create a directory for our certificates: $CERTS_DIR"
  sudo mkdir -p "$CERTS_DIR"
  cd "$CERTS_DIR" || return 1

  # Generating RSA private key, 2048 bit long modulus
  devmagic_log_info "Generating RSA private key, 2048 bit long modulus: $CERTS_DIR/$ROOT_CERT_NAME.key"
  sudo openssl genrsa -des3 -passout pass:"$PASS" -out "$ROOT_CERT_NAME".key 2048

  # Create config file for the root certificate
  devmagic_log_info "Create a temp config file with predefined parameters for the root certificate: $CERTS_DIR/$ROOT_CERT_NAME.conf"
  sudo tee "$ROOT_CERT_NAME".conf > /dev/null << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
[dn]
C = $COUNTRY
ST = $STATE
L = $STATE
O = $ORG
OU = $ORG_UNIT
CN = $COMMON_NAME
emailAddress = $EMAIL
EOF

  # Generate a root certificate
  devmagic_log_info "Generate a root certificate with parameters from the config file: $CERTS_DIR/$ROOT_CERT_NAME.pem"
  sudo openssl req -x509 -new -nodes -key "$ROOT_CERT_NAME".key -sha256 -days 1825 -out "$ROOT_CERT_NAME".pem -config "$ROOT_CERT_NAME".conf -passin pass:"$PASS"

  # Checking for ca-certificates package.
  REQUIRED_PKG="ca-certificates"
  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG|grep "install ok installed")
  devmagic_log_info "Checking for package $REQUIRED_PKG: $PKG_OK"
  if [ "" = "$PKG_OK" ]; then
    devmagic_log_warning "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
    sudo apt-get --yes install $REQUIRED_PKG
  fi

  CA_CERTS_DIR=/usr/local/share/ca-certificates

  # Copy the *.pem file to the /usr/local/share/ca-certificates directory as a *.crt file.
  devmagic_log_info "Copy the $ROOT_CERT_NAME.pem file to the $CA_CERTS_DIR directory as a $ROOT_CERT_NAME.crt file."
  sudo cp "$CERTS_DIR"/"$ROOT_CERT_NAME".pem "$CA_CERTS_DIR"/"$ROOT_CERT_NAME".crt

  # Update the certificate store
  devmagic_log_info "Update the certificate store..."
  sudo update-ca-certificates

  # Test that the certificate has been installed
  devmagic_log_info "Test that the certificate has been installed..."
  if awk -v cmd='openssl x509 -noout -subject' '/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt | grep -q "$ORG"; then
    devmagic_log_success "The certificate has been installed successfully!"
  else
    devmagic_log_error "The certificate is not installed!"
  fi

  # Remove temp files
  devmagic_log_info "Remove temp config file: $CERTS_DIR/$ROOT_CERT_NAME.conf"
  sudo rm "$ROOT_CERT_NAME".conf

  devmagic_log_warning "You may need to restart your browser or system to recognize the new CA."
  devmagic_log_warning "For Firefox, you may need to manually import the certificate \\nvia Settings > Privacy & Security > Certificates > View Certificates > Authorities > Import."
}

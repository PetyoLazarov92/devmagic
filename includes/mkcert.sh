#!/usr/bin/env bash
#
# Generating Certificate for specific domain

#######################################
# Function: mkcert
# Description: Creates a self-signed SSL certificate for a specified domain
#              using a local Certificate Authority.
#
# Prerequisites:
#   - OpenSSL must be installed
#   - Requires sudo privileges
#   - devmagic_config array must be initialized with CERTS_DIR and CERTS_ISSUER_DIR
#   - devmagic_config_defaults array must contain COUNTRY, STATE, ORG, ORG_UNIT, EMAIL, PASS
#   - mkcertissuer function must be available
#
# Arguments:
#   None directly, but requires the following variables to be set:
#   - domain: The domain name for which to create the certificate
#
# Environment:
#   - Uses devmagic_config and devmagic_config_defaults for configuration
#   - Requires devmagic_log_error and devmagic_log_info functions for logging
#
# Returns:
#   0 - Certificate successfully created
#   1 - Error occurred during certificate creation
#
# Output:
#   Creates the following files in $CERTS_DIR/$domain:
#   - $domain.key: Private key file
#   - $domain.csr: Certificate signing request
#   - $domain.crt: Signed certificate
#   - $domain.ext: Certificate extensions file (temporary)
#
# Example:
#   domain="example.com"
#   mkcert
#######################################
mkcert() {

  # Check if domain is provided
  if [ -z "$domain" ]; then
    devmagic_log_error "Domain is required. Please set the domain variable."
    return 1
  fi

  CERTS_DIR="${devmagic_config[CERTS_DIR]}"
  CERTS_ISSUER_DIR="${devmagic_config[CERTS_ISSUER_DIR]}"

  # Check for the cert issuer folder and files and create if not exists.
  if [ ! -d "$CERTS_ISSUER_DIR" ] || [ ! -f "$CERTS_ISSUER_DIR/LocalhostCA.pem" ] || [ ! -f "$CERTS_ISSUER_DIR/LocalhostCA.key" ]; then
    devmagic_log_info "Certificate issuer not found. Creating certificate issuer..."
    if ! mkcertissuer; then
      devmagic_log_error "Failed to create certificate issuer."
      return 1
    fi
  fi

  COUNTRY="${devmagic_config_defaults[COUNTRY]}"
  STATE="${devmagic_config_defaults[STATE]}"
  ORG="${devmagic_config_defaults[ORG]}"
  ORG_UNIT="${devmagic_config_defaults[ORG_UNIT]}"
  EMAIL="${devmagic_config_defaults[EMAIL]}"
  PASS="${devmagic_config_defaults[PASS]}"

  cd "$CERTS_DIR" || return 1

  sudo mkdir -p "${domain}"

  cd "$CERTS_DIR"/"${domain}" || return 1

  sudo openssl genrsa -out "${domain}".key 2048

  sudo tee "${domain}".conf > /dev/null <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
attributes = req_attributes
[dn]
C = $COUNTRY
ST = $STATE
L = $STATE
O = $ORG
OU = $ORG_UNIT
CN = ${domain}
emailAddress = $EMAIL
[req_attributes]
challengePassword = $PASS
EOF

  sudo openssl req -new -key "${domain}".key -out "${domain}".csr -config "${domain}".conf

  sudo tee "${domain}".ext > /dev/null <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${domain}
EOF

  sudo openssl x509 -req -in "${domain}".csr -CA "$CERTS_ISSUER_DIR"/LocalhostCA.pem -CAkey "$CERTS_ISSUER_DIR"/LocalhostCA.key -CAcreateserial \
  -out "${domain}".crt -days 825 -sha256 -extfile "${domain}".ext -passin pass:"$PASS"
  sudo rm "${domain}".conf
}
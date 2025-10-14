#!/bin/bash
#
# Create DEB Package for Dev Magic.
# This script creates a Debian package for system-wide installation.

set -e

PACKAGE_NAME="devmagic"
VERSION="1.0.0"
DEB_DIR="${PACKAGE_NAME}_${VERSION}"
ARCH="all"

# Clean previous builds
rm -rf "${DEB_DIR}" "${DEB_DIR}.deb"

echo "Creating DEB package structure..."

# Create package directory structure
mkdir -p "${DEB_DIR}/DEBIAN"
mkdir -p "${DEB_DIR}/usr/local/bin"
mkdir -p "${DEB_DIR}/usr/local/share/devmagic"
mkdir -p "${DEB_DIR}/usr/share/doc/devmagic"

# Copy source files to package
echo "Copying Dev Magic files..."
cp -r ../mklocalenv.sh "${DEB_DIR}/usr/local/share/devmagic/"
cp -r ../includes "${DEB_DIR}/usr/local/share/devmagic/"
cp -r ../tools "${DEB_DIR}/usr/local/share/devmagic/"
cp -r ../utilities "${DEB_DIR}/usr/local/share/devmagic/"

# Make main script executable
chmod +x "${DEB_DIR}/usr/local/share/devmagic/mklocalenv.sh"

# Create wrapper script for /usr/local/bin
cat > "${DEB_DIR}/usr/local/bin/devmagic" <<'EOF'
#!/bin/bash
# Dev Magic wrapper script
# Executes the main Dev Magic script with all provided arguments

exec /usr/local/share/devmagic/mklocalenv.sh "$@"
EOF

chmod +x "${DEB_DIR}/usr/local/bin/devmagic"

# Create control file
cat > "${DEB_DIR}/DEBIAN/control" <<EOF
Package: ${PACKAGE_NAME}
Version: ${VERSION}
Section: web
Priority: optional
Architecture: ${ARCH}
Maintainer: Web Timeless Ltd. <support@webtimeless.bg>
Description: Dev Magic - WordPress Local Development Environment Tool
 Dev Magic is a comprehensive tool for setting up local WordPress development
 environments. It provides automated SSL certificate generation, Apache
 configuration, WordPress installation, and project cloning capabilities.
 .
 Features:
  - SSL certificate generation with custom CA
  - Apache virtual host configuration
  - WordPress installation and setup
  - Database import functionality
  - Git project cloning
  - Interactive wizard mode
  - WordPress site cleanup and removal
Depends: bash (>= 4.0), apache2, mysql-server | mariadb-server, php, php-mysql, curl, git, openssl
Recommends: wp-cli, composer
Homepage: https://github.com/PetyoLazarov92/devmagic
EOF

# Create postinst script for post-installation tasks
cat > "${DEB_DIR}/DEBIAN/postinst" <<'EOF'
#!/bin/bash
set -e

echo "Setting up Dev Magic..."

# Enable Apache modules if not already enabled
if command -v a2enmod >/dev/null 2>&1; then
  a2enmod ssl >/dev/null 2>&1 || true
  a2enmod rewrite >/dev/null 2>&1 || true
fi

# Create certs directory if it doesn't exist
if [ ! -d "/etc/ssl/localcerts" ]; then
  sudo -u "$(logname)" mkdir -p "/etc/ssl/localcerts/cert-issuer"
fi

echo "Dev Magic installation completed successfully!"
echo "Run 'devmagic --help' to get started."

exit 0
EOF

chmod +x "${DEB_DIR}/DEBIAN/postinst"

# Create prerm script for pre-removal tasks
cat > "${DEB_DIR}/DEBIAN/prerm" <<'EOF'
#!/bin/bash
set -e

echo "Preparing to remove Dev Magic..."

# Add any cleanup tasks here if needed

# Clean up any Dev Magic-specific temporary files if they exist
if [ -d "/tmp/devmagic" ]; then
  rm -rf /tmp/devmagic
fi

# Note: We intentionally do NOT remove shared directories like /usr/local/share
# as they may contain files from other packages

echo "Dev Magic pre-removal cleanup completed."

exit 0
EOF

chmod +x "${DEB_DIR}/DEBIAN/prerm"

# Create postrm script for post-removal cleanup
cat > "${DEB_DIR}/DEBIAN/postrm" <<'EOF'
#!/bin/bash
set -e

case "$1" in
    remove|purge)
        echo "Dev Magic has been removed."
        
        # Only perform purge-specific cleanup on purge
        if [ "$1" = "purge" ]; then
            echo "Performing purge cleanup..."
            
            # Ask user if they want to remove certificates (only on purge)
            if [ -t 0 ]; then  # Check if we have an interactive terminal
                echo "Dev Magic certificates and configurations may still exist."
                echo "To manually remove them, check:"
                echo "  - /etc/ssl/localcerts (SSL certificates)"
                echo "  - /etc/apache2/sites-available/ (Apache configs)"
                echo "  - /var/www/local.* (WordPress installations)"
            fi
        fi
        ;;
    upgrade|failed-upgrade|abort-install|abort-upgrade|disappear)
        # Do nothing in these cases
        ;;
    *)
        echo "postrm called with unknown argument \`$1'" >&2
        exit 1
        ;;
esac

exit 0
EOF

chmod +x "${DEB_DIR}/DEBIAN/postrm"

# Create copyright file
cat > "${DEB_DIR}/usr/share/doc/devmagic/copyright" <<EOF
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: devmagic
Source: https://github.com/PetyoLazarov92/devmagic

Files: *
Copyright: $(date +%Y) Dev Magic Team
License: MIT

License: MIT
 Permission is hereby granted, free of charge, to any person obtaining a
 copy of this software and associated documentation files (the "Software"),
 to deal in the Software without restriction, including without limitation
 the rights to use, copy, modify, merge, publish, distribute, sublicense,
 and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 .
 The above copyright notice and this permission notice shall be included
 in all copies or substantial portions of the Software.
 .
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 DEALINGS IN THE SOFTWARE.
EOF

# Create changelog
cat > "${DEB_DIR}/usr/share/doc/devmagic/changelog.Debian" <<EOF
devmagic (${VERSION}) unstable; urgency=medium

  * Initial release of Dev Magic
  * WordPress local development environment setup
  * SSL certificate generation
  * Apache configuration automation
  * Database import functionality
  * Git project cloning
  * Interactive wizard mode
  * WordPress site cleanup and removal

 -- Web Timeless Ltd. <support@webtimeless.bg>  $(date -R)
EOF

gzip -9 "${DEB_DIR}/usr/share/doc/devmagic/changelog.Debian"

# Build the DEB package
echo "Building DEB package..."
dpkg-deb --build "${DEB_DIR}"

echo "DEB package created: ${DEB_DIR}.deb"
echo ""
echo "To install:"
echo "  sudo dpkg -i ${DEB_DIR}.deb"
echo "  sudo apt-get install -f  # Fix dependencies if needed"
echo ""
echo "To uninstall:"
echo "  sudo dpkg -r ${PACKAGE_NAME}"

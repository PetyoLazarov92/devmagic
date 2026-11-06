# Dev Magic - WordPress Local Development Environment Tool

[![Version](https://img.shields.io/badge/version-1.1.0-brightgreen)](CHANGELOG.md)
[![License](https://img.shields.io/badge/License-MIT-blue)](#-license)
[![bash](https://img.shields.io/badge/bash-4.0%2B-purple)](#required-dependencies)
[![Docs](https://img.shields.io/badge/docs-webtimeless.cloud-6d5dfc)](https://webtimeless.cloud/docs/devmagic-cli/)

> 🚀 Fast and automated local WordPress development environment setup with SSL certificates, Apache configuration, and project cloning.

<div align="center">
  <img src="assets/images/dev-magic.svg" alt="Dev Magic - WordPress Local Development Tool">
</div>

## 📋 Table of Contents
- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Command Options](#-command-options)
- [Examples](#-examples)
- [Prerequisites](#-prerequisites)
- [Directory Structure](#-directory-structure)
- [Configuration](#-configuration)
- [Development Workflow](#-development-workflow)
- [Uninstallation](#-uninstallation)
- [Troubleshooting](#-troubleshooting)
- [Adding Certificate Authority](#-adding-certificate-authority-to-browsers)
- [Security Considerations](#-security-considerations)
- [License](#-license)
- [Community Resources](#-community-resources)
- [Support Development](#-support-development)
- [Changelog](#-changelog)

## ✨ Features

- ✅ **SSL Certificate Generation**: Create self-signed certificates with custom CA following security standards
- ✅ **Apache Virtual Host Configuration**: Automated SSL-enabled virtual host setup
- ✅ **WordPress Installation**: Complete WordPress setup with database configuration following WP coding standards
- ✅ **Database Import**: Import existing WordPress databases
- ✅ **Git Project Cloning**: Clone multiple repositories to specific locations (themes, plugins, custom code)
- ✅ **Interactive Wizard**: Guided setup for beginners
- ✅ **Modular Architecture**: Clean, maintainable code structure
- ✅ **Site Cleanup**: Safely remove WordPress sites, databases, Apache configs, and SSL certificates

## 💻 Installation

### Method 1: One line (recommended)

```bash
curl -fsSL https://webtimeless.cloud/devmagic-cli.sh | bash
```

It downloads the newest [release](https://github.com/PetyoLazarov92/devmagic/releases),
checks it against its `.sha256`, and runs its `install.sh`, which asks for
sudo when it needs it. Run it as your own user, not root. To read the script
first, or pick a release:

```bash
curl -fsSLO https://github.com/PetyoLazarov92/devmagic/releases/latest/download/get.sh
bash get.sh --dry-run          # download and check, install nothing
bash get.sh --version v1.1.0   # a given release
```

### Method 2: From a checkout

```bash
# Clone the repository
git clone https://github.com/PetyoLazarov92/devmagic.git devmagic
cd devmagic

# Setup development environment
make dev-setup

# Install system-wide
make install
# or
bash install.sh
```

### Method 3: Debian Package

```bash
# Create DEB package
make deb

# Install the package
sudo dpkg -i devmagic_1.1.0.deb

# Install dependencies if needed
sudo apt-get install -f
```

### Method 4: Direct Usage (Development)

```bash
# Make executable and run directly
chmod +x mklocalenv.sh
./mklocalenv.sh --help
```

[⬆️ Back to top](#-table-of-contents)

## 🚀 Quick Start

After installation, you can use Dev Magic with the `devmagic` command:

```bash
# Show help and available options
devmagic --help

# Start interactive wizard (recommended for beginners)
devmagic --wizard

# Create complete local WordPress environment
devmagic -d local.example.com -c -w -cf \
  -dbn mydb -t "My Local WordPress Site"

# Import existing WordPress database
devmagic -d local.mysite.com -c -w -cf \
  -dbn mysitedb -dbf /path/to/database.sql \
  -pr "git@github.com:user/theme.git{to}/var/www/local.mysite.com/wp-content/themes"

# Clean up a WordPress site
devmagic -d local.mysite.com --remove

# Start the cleanup wizard
devmagic --remove-wizard
```

[⬆️ Back to top](#-table-of-contents)

## 🔧 Command Options

### Basic Options
- `-h, --help` - Show help message and usage examples
- `-v, --verbose` - Enable verbose output for debugging
- `-cwiz, --config-wizard` - Start the configuration wizard
- `-wiz, --wizard` - Start interactive wizard mode
- `-d, --domain` - Local domain name (e.g., local.example.com)

### Action Flags
- `-c, --cert` - Generate SSL certificate with custom CA
- `-w, --web` - Install WordPress with proper configuration
- `-cf, --config` - Create Apache virtual host configuration
- `-ci, --cert-issuer` - Create a local CA ([Certificate Authority](#-adding-certificate-authority-to-browsers)) for signing local SSL certificates

### WordPress Options
- `-dbn, --dbname` - Database name (following WP naming conventions)
- `-dbu, --dbuser` - Database user (default: root)
- `-dbp, --dbpass` - Database password (default: Root123@ - change for production!)
- `-dbpr, --dbprefix` - WordPress table prefix (default: wp_)
- `-dbf, --dbfile` - SQL file to import (WordPress database dump)
- `-t, --title` - WordPress site title

### Git Options
- `-pr, --projects` - Git repositories to clone (themes, plugins, custom code)
- `-cr, --content-repo` - Git repository URL for main project to clone into domain directory

### Cleanup Options
- `-rm, --remove` - Remove/cleanup a local WordPress site
- `-rmwiz, --remove-wizard` - Start the cleanup wizard

[⬆️ Back to top](#-table-of-contents)

## 📋 Examples

### Complete WordPress Development Setup
```bash
# Setup local WordPress site with SSL and custom theme
devmagic -d local.mysite.com -c -w -cf \
  -dbn mysite_db \
  -t "My Local WordPress Development Site" \
  -dbf ~/Downloads/production-database.sql \
  -pr "git@github.com:mycompany/custom-theme.git{to}/var/www/local.mysite.com/wp-content/themes"
```

### Multi-Project Setup
```bash
# Clone theme and plugin repositories
devmagic -pr "git@github.com:user/theme.git{to}/var/www/local.site.com/wp-content/themes{and}git@github.com:user/plugin.git{to}/var/www/local.site.com/wp-content/plugins"
```

### Using the Interactive Wizard
```bash
# Start guided setup (recommended for first-time users)
devmagic --wizard
```

### Cleaning up a WordPress Site
```bash
# Remove a site using the domain parameter
devmagic -d local.mysite.com --remove

# Use the interactive cleanup wizard
devmagic --remove-wizard
```

[⬆️ Back to top](#-table-of-contents)

## 📦 Prerequisites

### Required Dependencies
- bash (>= 4.0)
- apache2 (with mod_ssl and mod_rewrite)
- mysql-server or mariadb-server
- php (>= 7.4) and php-mysql
- curl (for WordPress downloads)
- git (for project cloning)
- openssl (for SSL certificate generation)

### Recommended Dependencies
- wp-cli (WordPress command line tool)
- composer (PHP dependency manager)
- mkcert (alternative SSL certificate tool)

Install dependencies on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install apache2 mysql-server php php-mysql php-curl php-gd php-xml php-zip curl git openssl

# Install WP-CLI (recommended)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
```

[⬆️ Back to top](#-table-of-contents)

## 📁 Directory Structure

Following coding standards and modular architecture:

```
devmagic/
├── mklocalenv.sh             # Main script entry point
├── install.sh                # System installation script
├── uninstall.sh              # Clean uninstallation script
├── Makefile                  # Build automation (follows make standards)
├── .gitignore                # Git ignore rules
├── LICENSE                   # MIT License
├── README.md                 # This documentation
├── build/                    # Build and packaging
│   └── create-deb-package.sh # Debian package creation
├── includes/                 # Core functionality modules
│   ├── mkcert.sh             # SSL certificate generation
│   ├── mkcertissuer.sh       # Certificate authority setup
│   ├── mkconfig-ssl.sh       # Apache configuration templates
│   ├── mkwpwebsite.sh        # WordPress installation logic
│   ├── rmwpwebsite.sh        # WordPress site cleanup logic
│   └── gitclone.sh           # Git repository cloning
├── tools/                    # Additional utilities
│   ├── wizard.sh             # Interactive setup wizard
│   ├── rmwizard.sh           # Interactive cleanup wizard
│   └── devmagic-conf.sh      # Configuration management
└── utilities/                # Helper functions
    └── checks.sh             # System and file validation
```

[⬆️ Back to top](#-table-of-contents)

## ⚙️ Configuration

Dev Magic uses a configuration file following WordPress configuration patterns:

```bash
# Edit configuration file
nano myscript.conf
```

Customizable settings:
- Default database credentials (change for production!)
- SSL certificate settings and CA configuration
- Apache virtual host templates
- WordPress default settings
- Git repository defaults

[⬆️ Back to top](#-table-of-contents)

## 👨‍💻 Development Workflow

### Setting Up Development Environment
```bash
# Clone and setup
git clone https://github.com/PetyoLazarov92/devmagic.git
cd devmagic
make dev-setup

# Run tests and linting
make test
make lint

# Build packages
make deb
```

### Contributing Guidelines
1. Fork the repository on GitHub
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Add tests for new functionality
4. Run linting: `make lint`
5. Commit changes: `git commit -m "Add amazing feature"`
6. Push to branch: `git push origin feature/amazing-feature`
7. Submit a Pull Request

[⬆️ Back to top](#-table-of-contents)

## 🗑️ Uninstallation

### System Installation
```bash
# Clean uninstall
make uninstall
# or
bash uninstall.sh
```

### DEB Package
```bash
# Remove package
sudo dpkg -r devmagic

# Purge configuration (optional)
sudo dpkg -P devmagic
```

[⬆️ Back to top](#-table-of-contents)

## ❓ Troubleshooting

### Common Issues

**Permission Denied Errors**
```bash
# Fix script permissions
chmod +x install.sh uninstall.sh mklocalenv.sh
sudo ./install.sh
```

**Missing Dependencies**
```bash
# Install all required packages
sudo apt update
sudo apt install apache2 mysql-server php php-mysql php-curl php-gd php-xml
```

**Apache Configuration Issues**
```bash
# Enable required modules
sudo a2enmod ssl rewrite
sudo systemctl restart apache2
```

**WordPress Installation Problems**
```bash
# Check WordPress requirements
php -m | grep -E "(mysql|curl|gd|xml)"
```

**Database Connection Issues**
- Ensure MySQL is running: `sudo systemctl start mysql`
- Verify database credentials in configuration
- Check if database exists: `mysql -u root -p -e "SHOW DATABASES;"`

**WordPress Cleanup Issues**
```bash
# Check if site directory exists
ls -la /var/www/local.mysite.com

# Check if Apache configuration exists
ls -la /etc/apache2/sites-available/local.mysite.com-ssl.conf

# Check if site is still enabled in Apache
ls -la /etc/apache2/sites-enabled/local.mysite.com-ssl.conf

# Manually check and remove hosts file entry
cat /etc/hosts | grep local.mysite.com
```

### Getting Help

1. Check this troubleshooting section
2. Review [GitHub Issues](https://github.com/PetyoLazarov92/devmagic/issues)
3. Create a new issue with:
   - System information (OS, versions)
   - Complete error messages
   - Steps to reproduce the problem

[⬆️ Back to top](#-table-of-contents)

## 🔒 Adding Certificate Authority to Browsers

For your local development sites to show the green padlock in browsers, you need to add the Dev Magic Certificate Authority (CA) to your browser's trusted certificate authorities. Below are instructions for various browsers:

### Chrome / Edge / Brave (Chromium-based browsers)

#### Method 1: Using Chrome Settings
1. Open Chrome and navigate to: `chrome://settings/certificates`
2. Click on the "Authorities" tab
3. Click "Import" and select your `LocalhostCA.pem` file (located in `/etc/ssl/localcerts/cert-issuer/`)
4. Check "Trust this certificate for identifying websites" and click "OK"
5. Restart your browser

#### Method 2: Using System Settings (Linux)
```bash
# Add to system-wide trusted certificates
sudo cp /etc/ssl/localcerts/cert-issuer/LocalhostCA.pem /usr/local/share/ca-certificates/LocalhostCA.crt
sudo update-ca-certificates
```

### Firefox

Firefox maintains its own certificate store:

1. Open Firefox and go to: `about:preferences#privacy`
2. Scroll down and click "View Certificates"
3. Click on the "Authorities" tab
4. Click "Import" and select your `LocalhostCA.pem` file from `/etc/ssl/localcerts/cert-issuer/`
5. Check "Trust this CA to identify websites" and click "OK"
6. Restart Firefox

### Safari (macOS)

1. Double-click on the `LocalhostCA.pem` file to open Keychain Access
2. The certificate will be automatically added to your login keychain
3. Find "Web Timeless Ltd." in the list, double-click it
4. Expand the "Trust" section
5. Change "When using this certificate" to "Always Trust"
6. Close the window (you may need to provide your password)
7. Restart Safari

### Android

1. Email the `LocalhostCA.pem` file to yourself or transfer it to your device
2. Go to Settings > Security > Encryption & Credentials > Install a certificate > CA certificate
3. Confirm with "Install anyway" if prompted
4. Select the certificate file you transferred
5. Restart your browser app

### iOS / iPadOS

1. Email the `LocalhostCA.pem` file to yourself or transfer it to your device
2. Open the file on your device
3. Go to Settings > General > Profile Downloaded
4. Tap "Install" in the top right
5. Enter your device passcode if prompted
6. Tap "Install" again on the warning screen
7. Go to Settings > General > About > Certificate Trust Settings
8. Enable full trust for the "Web Timeless Ltd." Root CA
9. Restart your browser app

### Verifying Certificate Installation

To verify that your certificate is properly installed and trusted:

1. Open your local development site (e.g., https://local.example.com)
2. Click on the padlock icon in the browser's address bar
3. The certificate should show as valid and issued by "Web Timeless Ltd."

### Troubleshooting Certificate Issues

If your browser still shows certificate warnings:

1. Make sure you're accessing the site with the exact domain name used during certificate generation
2. Check that the certificate was generated correctly:
   ```bash
   openssl x509 -in /etc/ssl/localcerts/cert-issuer/LocalhostCA.pem -text -noout
   ```
3. Verify the certificate matches the domain:
   ```bash
   openssl x509 -in /etc/ssl/localcerts/cert-issuer/LocalhostCA.pem -noout -subject
   ```
4. Try clearing your browser cache and restart the browser
5. For Chrome, also check `chrome://net-internals/#hsts` and delete domain security policies if needed

[⬆️ Back to top](#-table-of-contents)

## ⚠️ Security Considerations

**Important Security Notes:**

- This tool is designed for **development environments only**
- Default passwords should **never** be used in production
- SSL certificates are self-signed for local development
- Always change default credentials before production deployment

[⬆️ Back to top](#-table-of-contents)

## 📜 License

[![MIT License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Community Resources

- **GitHub Issues**: [Report bugs and request features](https://github.com/PetyoLazarov92/devmagic/issues)
- **Documentation**: [Wiki pages](https://github.com/PetyoLazarov92/devmagic/wiki)
- **Discussions**: [Community discussions](https://github.com/PetyoLazarov92/devmagic/discussions)

## ☕ Support Development

If you find Dev Magic useful in your workflow, consider supporting its development!

<a href="https://www.buymeacoffee.com/plazarov" target="_blank">
  <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="60" width="217" style="height: 60px !important;width: 217px !important;" >
</a>

Your support helps maintain this tool and develop new features. Every coffee counts toward:

- 🚀 Implementing new features
- 🐞 Fixing bugs
- 📖 Improving documentation
- 🧪 Adding tests
- 🔧 General maintenance and improvements

Dev Magic is a labor of love created to help WordPress developers setup local environments easily. Supporting it ensures that it continues to evolve with your needs.

## 📝 Changelog

Every release and what it changed is in [CHANGELOG.md](CHANGELOG.md), and on
[webtimeless.cloud](https://webtimeless.cloud/changelog/devmagic-cli/).

---

<div align="center">

**Made with 💚 for WordPress development**

[![Code Quality](https://img.shields.io/badge/code%20quality-A-brightgreen)](https://github.com/PetyoLazarov92/devmagic)
[![WordPress](https://img.shields.io/badge/WordPress-Ready-blue)](https://wordpress.org)
[![devmagic-panel](https://img.shields.io/badge/devmagic-panel-6d5dfc)](https://github.com/PetyoLazarov92/devmagic-panel)
[![webtimeless.cloud](https://img.shields.io/badge/webtimeless.cloud-docs%20and%20guides-6d5dfc)](https://webtimeless.cloud/)

</div>

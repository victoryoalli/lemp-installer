#!/bin/bash

###############################################################################
# LEMP Stack Installation Script for Laravel on Ubuntu 24
# Author: Victor Yoalli
# Repository: https://github.com/victoryoalli/lemp-installer
# Website: https://victoryoalli.me
# 
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh | sudo bash
#
# Or download and run:
#   curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/main/install.sh -o install.sh
#   chmod +x install.sh
#   sudo ./install.sh
###############################################################################

set -e  # Exit on error

# Script version
VERSION="1.0.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${MAGENTA}[STEP]${NC} $1"
}

# Function to prompt with default value
prompt_with_default() {
    local prompt="$1"
    local default="$2"
    local result
    
    read -p "$prompt [$default]: " result
    echo "${result:-$default}"
}

# Function to prompt yes/no with default
prompt_yes_no() {
    local prompt="$1"
    local default="$2"
    local result
    
    if [ "$default" = "y" ]; then
        read -p "$prompt [Y/n]: " result
        result="${result:-y}"
    else
        read -p "$prompt [y/N]: " result
        result="${result:-n}"
    fi
    
    [[ "$result" =~ ^[Yy]$ ]]
}

###############################################################################
# Check if running as root
###############################################################################
if [ "$EUID" -ne 0 ]; then 
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

###############################################################################
# Check Ubuntu version
###############################################################################
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_warning "This script is designed for Ubuntu. Your OS: $ID"
        if ! prompt_yes_no "Continue anyway?" "n"; then
            exit 1
        fi
    fi
    print_info "Detected OS: $PRETTY_NAME"
    
    # Check Ubuntu version
    VERSION_NUMBER=$(echo "$VERSION_ID" | cut -d. -f1)
    if [ "$VERSION_NUMBER" -lt 22 ]; then
        print_warning "This script is optimized for Ubuntu 22.04 or later. Your version: $VERSION_ID"
        if ! prompt_yes_no "Continue anyway?" "n"; then
            exit 1
        fi
    fi
fi

###############################################################################
# Welcome message
###############################################################################
clear
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   LEMP Stack Installation Script for Laravel on Ubuntu    ║"
echo "║                     Version $VERSION                         ║"
echo "║              https://victoryoalli.me                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
print_info "This script will install and configure:"
echo "  - Nginx (latest)"
echo "  - MySQL 8.0+"
echo "  - PHP 8.3 with Laravel extensions"
echo "  - Composer (latest)"
echo "  - Certbot for SSL (optional)"
echo "  - UFW Firewall (optional)"
echo "  - WordPress packages (optional)"
echo ""
print_info "Repository: https://github.com/victoryoalli/lemp-installer"
echo ""

if ! prompt_yes_no "Do you want to continue?" "y"; then
    print_info "Installation cancelled."
    exit 0
fi

###############################################################################
# Collect configuration parameters
###############################################################################
echo ""
print_step "Configuration parameters"
echo ""

# MySQL configuration
MYSQL_USER=$(prompt_with_default "MySQL username for web applications" "web")
MYSQL_PASSWORD=""
while [ -z "$MYSQL_PASSWORD" ]; do
    read -sp "MySQL password for user '$MYSQL_USER': " MYSQL_PASSWORD
    echo ""
    if [ -z "$MYSQL_PASSWORD" ]; then
        print_warning "Password cannot be empty. Please try again."
    fi
done

# Confirm password
MYSQL_PASSWORD_CONFIRM=""
read -sp "Confirm MySQL password: " MYSQL_PASSWORD_CONFIRM
echo ""
if [ "$MYSQL_PASSWORD" != "$MYSQL_PASSWORD_CONFIRM" ]; then
    print_error "Passwords do not match!"
    exit 1
fi

# System user configuration
SYSTEM_USER=$(prompt_with_default "System username for web applications" "web")

# Site configuration
SITE_NAME=$(prompt_with_default "Site name (used for nginx config filename)" "mysite")
DOMAIN_NAME=$(prompt_with_default "Domain name (e.g., example.com)" "")

# PHP version
PHP_VERSION="8.3"
print_info "Will use PHP version: $PHP_VERSION"

# Optional installations
INSTALL_WORDPRESS=false
if prompt_yes_no "Install WordPress packages?" "n"; then
    INSTALL_WORDPRESS=true
fi

INSTALL_SSL=false
SSL_EMAIL=""
if [ -n "$DOMAIN_NAME" ]; then
    if prompt_yes_no "Install and configure SSL with Let's Encrypt?" "y"; then
        INSTALL_SSL=true
        SSL_EMAIL=$(prompt_with_default "Email for SSL certificate" "admin@$DOMAIN_NAME")
    fi
fi

SETUP_SSH_KEYS=false
SSH_KEY_EMAIL=""
if prompt_yes_no "Setup SSH keys for deployment?" "y"; then
    SETUP_SSH_KEYS=true
    SSH_KEY_EMAIL=$(prompt_with_default "Email for SSH key" "$SYSTEM_USER@${DOMAIN_NAME:-localhost}")
fi

SETUP_FIREWALL=false
if prompt_yes_no "Configure UFW firewall?" "y"; then
    SETUP_FIREWALL=true
fi

###############################################################################
# Summary and confirmation
###############################################################################
echo ""
print_step "Configuration summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MySQL User:           $MYSQL_USER"
echo "System User:          $SYSTEM_USER"
echo "Site Name:            $SITE_NAME"
echo "Domain:               ${DOMAIN_NAME:-Not configured}"
echo "PHP Version:          $PHP_VERSION"
echo "Install WordPress:    $INSTALL_WORDPRESS"
echo "Install SSL:          $INSTALL_SSL"
echo "Setup SSH Keys:       $SETUP_SSH_KEYS"
echo "Setup Firewall:       $SETUP_FIREWALL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if ! prompt_yes_no "Proceed with installation?" "y"; then
    print_info "Installation cancelled."
    exit 0
fi

# Log file
LOG_FILE="/var/log/lemp-install-$(date +%Y%m%d-%H%M%S).log"
print_info "Installation log will be saved to: $LOG_FILE"

# Redirect output to log file while still showing on screen
exec > >(tee -a "$LOG_FILE")
exec 2>&1

###############################################################################
# Step 1: Update and Install Packages
###############################################################################
echo ""
print_step "Step 1/8: Updating system and installing packages"

export DEBIAN_FRONTEND=noninteractive

print_info "Updating package lists..."
apt update

print_info "Upgrading installed packages..."
apt upgrade -y

print_info "Installing core packages (Nginx, MySQL, PHP)..."
apt install -y nginx mysql-server php-fpm php-mysql acl zip curl wget git unzip

print_info "Installing PHP extensions for Laravel..."
apt install -y \
    php-fpm \
    php-cli \
    php-common \
    php-mysql \
    php-zip \
    php-gd \
    php-mbstring \
    php-curl \
    php-xml \
    php-bcmath \
    openssl \
    php-tokenizer \
    php-json \
    php-intl

print_success "All packages installed successfully!"

###############################################################################
# Step 2: Configure MySQL
###############################################################################
echo ""
print_step "Step 2/8: Configuring MySQL"

# Start MySQL if not running
print_info "Starting MySQL service..."
systemctl start mysql
systemctl enable mysql

# Create MySQL user and grant privileges
print_info "Creating MySQL user '$MYSQL_USER'..."
mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';" 2>/dev/null || true
mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;"
mysql -e "FLUSH PRIVILEGES;"

# Test MySQL connection
if mysql -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; then
    print_success "MySQL user '$MYSQL_USER' created and configured successfully!"
else
    print_error "Failed to create or configure MySQL user"
    exit 1
fi

###############################################################################
# Step 3: Create System User and SSH Configuration
###############################################################################
echo ""
print_step "Step 3/8: Setting up system user"

# Create user if doesn't exist
if ! id "$SYSTEM_USER" &>/dev/null; then
    print_info "Creating user '$SYSTEM_USER'..."
    adduser --disabled-password --gecos "" "$SYSTEM_USER"
    print_success "User '$SYSTEM_USER' created!"
else
    print_warning "User '$SYSTEM_USER' already exists, skipping creation."
fi

# Setup SSH directory
print_info "Setting up SSH directory..."
su - "$SYSTEM_USER" -c "mkdir -p ~/.ssh"
su - "$SYSTEM_USER" -c "touch ~/.ssh/authorized_keys"
su - "$SYSTEM_USER" -c "chmod 700 ~/.ssh"
su - "$SYSTEM_USER" -c "chmod 600 ~/.ssh/authorized_keys"

# Add SSH public key
if prompt_yes_no "Do you want to add an SSH public key for user '$SYSTEM_USER'?" "y"; then
    echo ""
    print_info "Please paste your SSH public key (press Enter when done):"
    read -r SSH_PUBLIC_KEY
    
    if [ -n "$SSH_PUBLIC_KEY" ]; then
        su - "$SYSTEM_USER" -c "echo '$SSH_PUBLIC_KEY' >> ~/.ssh/authorized_keys"
        print_success "SSH public key added!"
    fi
fi

# Set home directory permissions
chmod 755 /home/"$SYSTEM_USER"

# Generate SSH keys for deployment
if [ "$SETUP_SSH_KEYS" = true ]; then
    print_info "Generating SSH key pair for deployment..."
    su - "$SYSTEM_USER" -c "ssh-keygen -t ed25519 -C '$SSH_KEY_EMAIL' -f ~/.ssh/id_ed25519 -N '' >/dev/null 2>&1"
    print_success "SSH key pair generated!"
    echo ""
    print_info "Public key for GitHub/GitLab (copy this):"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    su - "$SYSTEM_USER" -c "cat ~/.ssh/id_ed25519.pub"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    print_warning "IMPORTANT: Copy the above public key and add it to your repository!"
    read -p "Press Enter to continue..."
fi

###############################################################################
# Step 4: Configure Nginx
###############################################################################
echo ""
print_step "Step 4/8: Configuring Nginx"

# Start Nginx
print_info "Starting Nginx service..."
systemctl start nginx
systemctl enable nginx

# Remove default site if exists
if [ -L /etc/nginx/sites-enabled/default ]; then
    unlink /etc/nginx/sites-enabled/default
    print_info "Default site removed."
fi

# Create site directory structure
print_info "Creating web directory structure..."
su - "$SYSTEM_USER" -c "mkdir -p ~/www/current/public"
su - "$SYSTEM_USER" -c "echo '<?php phpinfo(); ?>' > ~/www/current/public/index.php"

# Detect PHP-FPM socket
PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

if [ ! -S "$PHP_SOCKET" ]; then
    print_warning "PHP-FPM socket not found at $PHP_SOCKET"
    print_info "Starting PHP-FPM service..."
    systemctl start php${PHP_VERSION}-fpm
    systemctl enable php${PHP_VERSION}-fpm
    sleep 2
fi

# Create Nginx configuration
print_info "Creating Nginx configuration..."
NGINX_CONFIG="/etc/nginx/sites-available/$SITE_NAME"

cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    listen [::]:80;
    
    server_name ${DOMAIN_NAME:-localhost};
    root /home/$SYSTEM_USER/www/current/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.html index.php;

    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCKET;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

# Enable site
ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/

# Test Nginx configuration
print_info "Testing Nginx configuration..."
if nginx -t 2>&1 | grep -q "successful"; then
    systemctl restart nginx
    print_success "Nginx configured and restarted successfully!"
else
    print_error "Nginx configuration test failed!"
    nginx -t
    exit 1
fi

###############################################################################
# Step 5: Install Composer
###############################################################################
echo ""
print_step "Step 5/8: Installing Composer"

if ! command -v composer &> /dev/null; then
    print_info "Downloading Composer installer..."
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        print_error "Composer installer corrupt"
        rm composer-setup.php
        exit 1
    fi

    print_info "Installing Composer..."
    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    rm composer-setup.php
    print_success "Composer installed successfully!"
    composer --version
else
    print_info "Composer already installed"
    composer --version
fi

###############################################################################
# Step 6: Install WordPress Packages (Optional)
###############################################################################
if [ "$INSTALL_WORDPRESS" = true ]; then
    echo ""
    print_step "Step 6/8: Installing WordPress packages"
    
    apt install -y \
        php-gd \
        php-curl \
        php-dom \
        php-imagick \
        php-mbstring \
        php-zip \
        php-intl
    
    systemctl restart php${PHP_VERSION}-fpm
    print_success "WordPress packages installed!"
else
    echo ""
    print_step "Step 6/8: Skipping WordPress packages"
fi

###############################################################################
# Step 7: Configure SSL with Let's Encrypt (Optional)
###############################################################################
if [ "$INSTALL_SSL" = true ]; then
    echo ""
    print_step "Step 7/8: Setting up SSL with Let's Encrypt"
    
    # Install snapd if not present
    if ! command -v snap &> /dev/null; then
        print_info "Installing snapd..."
        apt install -y snapd
        systemctl start snapd
        systemctl enable snapd
        sleep 5
    fi
    
    # Install certbot
    print_info "Installing Certbot..."
    snap install core 2>/dev/null || snap refresh core
    snap install --classic certbot
    ln -sf /snap/bin/certbot /usr/bin/certbot
    
    print_info "Obtaining SSL certificate for $DOMAIN_NAME..."
    print_warning "Make sure your domain is pointing to this server's IP address!"
    echo ""
    
    if prompt_yes_no "Proceed with SSL certificate request?" "y"; then
        if certbot --nginx -d "$DOMAIN_NAME" --non-interactive --agree-tos --email "$SSL_EMAIL" --redirect 2>&1 | tee -a "$LOG_FILE"; then
            print_success "SSL certificate installed and configured!"
            
            # Setup auto-renewal
            systemctl enable snap.certbot.renew.timer 2>/dev/null || true
            print_success "SSL auto-renewal configured!"
        else
            print_warning "SSL installation failed. You can try again later with:"
            echo "  sudo certbot --nginx -d $DOMAIN_NAME"
        fi
    else
        print_info "You can run 'sudo certbot --nginx -d $DOMAIN_NAME' later to install SSL."
    fi
else
    echo ""
    print_step "Step 7/8: Skipping SSL configuration"
fi

###############################################################################
# Step 8: Configure Firewall (Optional)
###############################################################################
if [ "$SETUP_FIREWALL" = true ]; then
    echo ""
    print_step "Step 8/8: Configuring UFW firewall"
    
    apt install -y ufw
    
    print_info "Configuring firewall rules..."
    # Allow SSH first (important!)
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    
    # Enable firewall
    print_warning "Enabling firewall. Make sure you have SSH access configured!"
    if prompt_yes_no "Enable firewall now?" "y"; then
        echo "y" | ufw enable
        print_success "Firewall configured and enabled!"
        ufw status
    else
        print_info "Firewall rules configured but not enabled. Run 'sudo ufw enable' when ready."
    fi
else
    echo ""
    print_step "Step 8/8: Skipping firewall configuration"
fi

###############################################################################
# Installation Complete
###############################################################################
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Installation Completed Successfully!         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
print_success "LEMP Stack v${VERSION} has been installed and configured!"
echo ""
print_info "Configuration details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Web root:             /home/$SYSTEM_USER/www/current/public"
echo "Nginx config:         /etc/nginx/sites-available/$SITE_NAME"
echo "PHP version:          $PHP_VERSION"
echo "PHP socket:           $PHP_SOCKET"
echo "MySQL user:           $MYSQL_USER"
echo "System user:          $SYSTEM_USER"
echo "Log file:             $LOG_FILE"
if [ -n "$DOMAIN_NAME" ]; then
    echo "Domain:               $DOMAIN_NAME"
    if [ "$INSTALL_SSL" = true ]; then
        echo "SSL:                  Enabled (https://$DOMAIN_NAME)"
    fi
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Next steps for Laravel deployment:"
echo ""
echo "  1. Switch to web user:"
echo "     sudo su - $SYSTEM_USER"
echo ""
echo "  2. Clone your repository:"
echo "     cd ~/www"
echo "     git clone YOUR_REPO current"
echo "     cd current"
echo ""
echo "  3. Install dependencies:"
echo "     composer install --no-dev --optimize-autoloader"
echo ""
echo "  4. Configure environment:"
echo "     cp .env.example .env"
echo "     nano .env"
echo ""
echo "  5. Run Laravel setup:"
echo "     php artisan key:generate"
echo "     php artisan migrate --force"
echo "     php artisan config:cache"
echo "     php artisan route:cache"
echo "     php artisan view:cache"
echo ""
echo "  6. Set permissions:"
echo "     chmod -R 775 storage bootstrap/cache"
echo ""
print_info "Test your installation:"
if [ -n "$DOMAIN_NAME" ]; then
    if [ "$INSTALL_SSL" = true ]; then
        echo "  Visit: https://$DOMAIN_NAME"
    else
        echo "  Visit: http://$DOMAIN_NAME"
    fi
else
    echo "  Get your server IP: ip addr show | grep 'inet ' | grep -v '127.0.0.1'"
    echo "  Visit: http://YOUR_SERVER_IP"
fi
echo ""
print_warning "IMPORTANT: Save these credentials securely!"
echo "  MySQL User: $MYSQL_USER"
echo "  MySQL Password: [hidden]"
echo ""
print_info "Useful commands:"
echo "  sudo systemctl status nginx          # Check Nginx"
echo "  sudo systemctl status php${PHP_VERSION}-fpm   # Check PHP-FPM"
echo "  sudo systemctl status mysql          # Check MySQL"
echo "  sudo tail -f /var/log/nginx/error.log   # View Nginx logs"
echo ""
print_success "Installation complete! 🚀"
echo ""
print_info "Documentation: https://github.com/victoryoalli/lemp-installer"
print_info "Support: https://victoryoalli.me/ubuntu-lemp-install"

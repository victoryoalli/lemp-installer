#!/bin/bash

###############################################################################
# LEMP Stack Installation Script for Laravel on Ubuntu 24
# Author: Victor Yoalli
# Repository: https://github.com/victoryoalli/lemp-installer
# Website: https://victoryoalli.me
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh | sudo bash
#
# Or download and run:
#   curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh -o install.sh
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
echo "  - Database (MySQL 8.0+ or PostgreSQL 15+)"
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
# Input validation functions
###############################################################################

validate_unix_name() {
    local val="$1" label="$2"
    if ! [[ "$val" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        print_error "$label must start with a letter or underscore, contain only a-z, 0-9, _ or -, and be at most 32 characters."
        return 1
    fi
    return 0
}

validate_site_name() {
    local val="$1"
    if ! [[ "$val" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Site name must contain only letters, numbers, underscores, or hyphens."
        return 1
    fi
    return 0
}

validate_domain() {
    local val="$1"
    if [[ -n "$val" ]] && ! [[ "$val" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        print_error "Invalid domain name format."
        return 1
    fi
    return 0
}

###############################################################################
# Collect configuration parameters
###############################################################################
echo ""
print_step "Configuration parameters"
echo ""

# Database selection
echo "Select your database:"
echo "  1) MySQL 8.0+"
echo "  2) PostgreSQL 15+"
DB_CHOICE=""
while [[ ! "$DB_CHOICE" =~ ^[12]$ ]]; do
    read -p "Enter your choice (1-2): " DB_CHOICE
    case $DB_CHOICE in
        1)
            DATABASE_TYPE="mysql"
            DATABASE_NAME="MySQL"
            print_info "Selected: MySQL 8.0+"
            ;;
        2)
            DATABASE_TYPE="postgresql"
            DATABASE_NAME="PostgreSQL"
            print_info "Selected: PostgreSQL 15+"
            ;;
        *)
            print_warning "Invalid choice. Please enter 1 for MySQL or 2 for PostgreSQL."
            ;;
    esac
done

# Database configuration
if [ "$DATABASE_TYPE" = "mysql" ]; then
    DB_USER=""
    while true; do
        DB_USER=$(prompt_with_default "MySQL username for web applications" "web")
        validate_unix_name "$DB_USER" "MySQL username" && break
    done
    DB_PASSWORD=""
    while [ -z "$DB_PASSWORD" ]; do
        read -sp "MySQL password for user '$DB_USER': " DB_PASSWORD
        echo ""
        if [ -z "$DB_PASSWORD" ]; then
            print_warning "Password cannot be empty. Please try again."
        fi
    done
else
    DB_USER=""
    while true; do
        DB_USER=$(prompt_with_default "PostgreSQL username for web applications" "web")
        validate_unix_name "$DB_USER" "PostgreSQL username" && break
    done
    DB_PASSWORD=""
    while [ -z "$DB_PASSWORD" ]; do
        read -sp "PostgreSQL password for user '$DB_USER': " DB_PASSWORD
        echo ""
        if [ -z "$DB_PASSWORD" ]; then
            print_warning "Password cannot be empty. Please try again."
        fi
    done
fi

# Confirm password
DB_PASSWORD_CONFIRM=""
read -sp "Confirm $DATABASE_NAME password: " DB_PASSWORD_CONFIRM
echo ""
if [ "$DB_PASSWORD" != "$DB_PASSWORD_CONFIRM" ]; then
    print_error "Passwords do not match!"
    exit 1
fi

# System user configuration
SYSTEM_USER=""
while true; do
    SYSTEM_USER=$(prompt_with_default "System username for web applications" "web")
    validate_unix_name "$SYSTEM_USER" "System username" && break
done

# Site configuration
SITE_NAME=""
while true; do
    SITE_NAME=$(prompt_with_default "Site name (used for nginx config filename)" "mysite")
    validate_site_name "$SITE_NAME" && break
done
DOMAIN_NAME=""
while true; do
    DOMAIN_NAME=$(prompt_with_default "Domain name (e.g., example.com)" "")
    validate_domain "$DOMAIN_NAME" && break
done

# PHP version
PHP_VERSION="8.3"
print_info "Will use PHP version: $PHP_VERSION"

# Optional installations
INSTALL_WORDPRESS=false
if prompt_yes_no "Install WordPress packages?" "n"; then
    INSTALL_WORDPRESS=true
fi

INSTALL_SSL=false
SSL_TYPE="standard"
SSL_EMAIL=""
if [ -n "$DOMAIN_NAME" ]; then
    if prompt_yes_no "Install and configure SSL with Let's Encrypt?" "y"; then
        INSTALL_SSL=true
        SSL_EMAIL=$(prompt_with_default "Email for SSL certificate" "admin@$DOMAIN_NAME")

        echo ""
        echo "Select SSL certificate type:"
        echo "  1) Standard  — single domain (HTTP challenge, fully automated)"
        echo "  2) Wildcard  — *.${DOMAIN_NAME} (DNS challenge, requires manual DNS record)"
        SSL_CHOICE=""
        while [[ ! "$SSL_CHOICE" =~ ^[12]$ ]]; do
            read -p "Enter your choice (1-2): " SSL_CHOICE
        done
        if [ "$SSL_CHOICE" = "2" ]; then
            SSL_TYPE="wildcard"
            print_info "Selected: Wildcard certificate (*.${DOMAIN_NAME} + ${DOMAIN_NAME})"
            print_warning "You will need to add a TXT DNS record during the certificate request."
        else
            SSL_TYPE="standard"
            print_info "Selected: Standard certificate (${DOMAIN_NAME})"
        fi
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
echo "Database:             $DATABASE_NAME"
echo "Database User:        $DB_USER"
echo "System User:          $SYSTEM_USER"
echo "Site Name:            $SITE_NAME"
echo "Domain:               ${DOMAIN_NAME:-Not configured}"
echo "PHP Version:          $PHP_VERSION"
echo "Install WordPress:    $INSTALL_WORDPRESS"
echo "Install SSL:          $INSTALL_SSL${INSTALL_SSL:+ ($SSL_TYPE)}"
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
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
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

# Install database packages based on selection
if [ "$DATABASE_TYPE" = "mysql" ]; then
    print_info "Installing core packages (Nginx, MySQL, PHP)..."
    apt install -y nginx mysql-server php-fpm php-mysql acl zip curl wget git unzip
else
    print_info "Installing core packages (Nginx, PostgreSQL, PHP)..."
    apt install -y nginx postgresql postgresql-contrib php-fpm php-pgsql acl zip curl wget git unzip
fi

print_info "Installing PHP extensions for Laravel..."
if [ "$DATABASE_TYPE" = "mysql" ]; then
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
else
    apt install -y \
        php-fpm \
        php-cli \
        php-common \
        php-pgsql \
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
fi

print_success "All packages installed successfully!"

###############################################################################
# Step 2: Configure Database
###############################################################################
echo ""
print_step "Step 2/8: Configuring $DATABASE_NAME"

if [ "$DATABASE_TYPE" = "mysql" ]; then
    # Start MySQL if not running
    print_info "Starting MySQL service..."
    systemctl start mysql
    systemctl enable mysql

    # Create MySQL user and grant privileges
    print_info "Creating MySQL user '$DB_USER'..."
    MYSQL_ERR=$(mktemp)

    # Drop and recreate user to ensure correct password/auth plugin
    mysql 2>"$MYSQL_ERR" <<EOF
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    MYSQL_EXIT=$?
    if [ $MYSQL_EXIT -ne 0 ]; then
        print_error "Failed to configure MySQL user. MySQL said:"
        cat "$MYSQL_ERR" >&2
        rm -f "$MYSQL_ERR"
        exit 1
    fi
    rm -f "$MYSQL_ERR"

    # Test MySQL connection using a temp config file to avoid password in process list
    MYSQL_TEST_CNF=$(mktemp)
    chmod 600 "$MYSQL_TEST_CNF"
    printf '[client]\nuser=%s\npassword=%s\n' "$DB_USER" "$DB_PASSWORD" > "$MYSQL_TEST_CNF"
    if mysql --defaults-extra-file="$MYSQL_TEST_CNF" -e "SELECT 1;" >/dev/null 2>&1; then
        rm -f "$MYSQL_TEST_CNF"
        print_success "MySQL user '$DB_USER' created and configured successfully!"
    else
        rm -f "$MYSQL_TEST_CNF"
        print_error "Failed to connect as MySQL user '$DB_USER' after creation"
        exit 1
    fi
else
    # Start PostgreSQL if not running
    print_info "Starting PostgreSQL service..."
    systemctl start postgresql
    systemctl enable postgresql

    # Switch to postgres user to create database user
    print_info "Creating PostgreSQL user '$DB_USER'..."
    sudo -u postgres psql -c "CREATE USER \"${DB_USER}\" WITH PASSWORD '${DB_PASSWORD}';" 2>/dev/null || true
    sudo -u postgres psql -c "ALTER USER \"${DB_USER}\" CREATEDB;" 2>/dev/null || true
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE postgres TO \"${DB_USER}\";" 2>/dev/null || true

    # Test PostgreSQL connection as the created user (not as postgres superuser)
    if PGPASSWORD="$DB_PASSWORD" psql -h localhost -U "$DB_USER" -d postgres -c "SELECT 1;" >/dev/null 2>&1; then
        print_success "PostgreSQL user '$DB_USER' created and verified!"
    else
        print_error "Failed to connect as PostgreSQL user '$DB_USER'"
        exit 1
    fi
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
        echo "$SSH_PUBLIC_KEY" | su - "$SYSTEM_USER" -c "cat >> ~/.ssh/authorized_keys"
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

if [ "$SSL_TYPE" = "wildcard" ] && [ -n "$DOMAIN_NAME" ]; then
    NGINX_SERVER_NAME="${DOMAIN_NAME} *.${DOMAIN_NAME}"
else
    NGINX_SERVER_NAME="${DOMAIN_NAME:-localhost}"
fi

if [ "$INSTALL_WORDPRESS" = true ]; then
    cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${NGINX_SERVER_NAME};
    root /home/$SYSTEM_USER/www/current/public;

    client_max_body_size 64M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";

    index index.html index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location = /xmlrpc.php { deny all; access_log off; log_not_found off; }
    location = /wp-config.php { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
else
    cat > "$NGINX_CONFIG" << EOF
server {
    listen 80;
    listen [::]:80;

    server_name ${NGINX_SERVER_NAME};
    root /home/$SYSTEM_USER/www/current/public;

    client_max_body_size 100M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";

    index index.html index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    error_page 404 /index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF
fi

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

    if [ "$SSL_TYPE" = "wildcard" ]; then
        print_info "Requesting wildcard certificate for *.${DOMAIN_NAME} and ${DOMAIN_NAME}..."
        print_warning "Certbot will pause and ask you to create a DNS TXT record."
        print_warning "Log in to your DNS provider and add the record before pressing Enter."
        echo ""

        if certbot certonly --manual --preferred-challenges dns \
            -d "*.${DOMAIN_NAME}" -d "${DOMAIN_NAME}" \
            --agree-tos --email "$SSL_EMAIL" \
            --manual-public-ip-logging-ok 2>&1 | tee -a "$LOG_FILE"; then

            print_success "Wildcard certificate obtained!"

            NGINX_CONFIG="/etc/nginx/sites-available/$SITE_NAME"
            CERT_PATH="/etc/letsencrypt/live/${DOMAIN_NAME}"

            if [ "$INSTALL_WORDPRESS" = true ]; then
                cat > "$NGINX_CONFIG" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN_NAME} *.${DOMAIN_NAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${DOMAIN_NAME} *.${DOMAIN_NAME};
    root /home/$SYSTEM_USER/www/current/public;

    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 64M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    index index.html index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location = /xmlrpc.php { deny all; access_log off; log_not_found off; }
    location = /wp-config.php { deny all; }
    location ~* /(?:uploads|files)/.*\.php$ { deny all; }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINXEOF
            else
                cat > "$NGINX_CONFIG" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN_NAME} *.${DOMAIN_NAME};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${DOMAIN_NAME} *.${DOMAIN_NAME};
    root /home/$SYSTEM_USER/www/current/public;

    ssl_certificate ${CERT_PATH}/fullchain.pem;
    ssl_certificate_key ${CERT_PATH}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 100M;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    index index.html index.php;
    charset utf-8;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    error_page 404 /index.php;

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCKET};
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINXEOF
            fi

            nginx -t && systemctl reload nginx
            print_success "Nginx updated with wildcard SSL!"

            print_warning "IMPORTANT: Wildcard certificates obtained via manual DNS challenge"
            print_warning "cannot be renewed automatically. Run the following before expiry (every 90 days):"
            echo "  sudo certbot renew --manual --preferred-challenges dns"

        else
            print_warning "Wildcard SSL request failed or was cancelled."
            print_info "You can retry later with:"
            echo "  sudo certbot certonly --manual --preferred-challenges dns \\"
            echo "    -d '*.${DOMAIN_NAME}' -d '${DOMAIN_NAME}'"
        fi
    else
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
echo "Database:             $DATABASE_NAME"
echo "Database user:        $DB_USER"
echo "System user:          $SYSTEM_USER"
echo "Log file:             $LOG_FILE"
if [ -n "$DOMAIN_NAME" ]; then
    echo "Domain:               $DOMAIN_NAME"
    if [ "$INSTALL_SSL" = true ]; then
        if [ "$SSL_TYPE" = "wildcard" ]; then
            echo "SSL:                  Wildcard (https://*.${DOMAIN_NAME})"
        else
            echo "SSL:                  Enabled (https://$DOMAIN_NAME)"
        fi
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
echo "  Database: $DATABASE_NAME"
echo "  Database User: $DB_USER"
echo "  Database Password: [hidden]"
echo ""
print_info "Useful commands:"
echo "  sudo systemctl status nginx          # Check Nginx"
echo "  sudo systemctl status php${PHP_VERSION}-fpm   # Check PHP-FPM"
if [ "$DATABASE_TYPE" = "mysql" ]; then
    echo "  sudo systemctl status mysql          # Check MySQL"
else
    echo "  sudo systemctl status postgresql     # Check PostgreSQL"
fi
echo "  sudo tail -f /var/log/nginx/error.log   # View Nginx logs"
echo ""
print_success "Installation complete! 🚀"
echo ""
print_info "Documentation: https://github.com/victoryoalli/lemp-installer"
print_info "Support: https://victoryoalli.me/ubuntu-lemp-install"

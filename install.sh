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
#
# Apply SSL Nginx config after obtaining a certificate:
#   sudo ./install.sh --apply-ssl
#
# Re-apply PHP settings (e.g. after a PHP version upgrade):
#   sudo ./install.sh --reconfigure-php
#   sudo ./install.sh --reconfigure-php 8.4
#
# Retrofit an existing server (per-user PHP-FPM pool, permissions, nginx socket):
#   sudo ./install.sh --fix-permissions
#
# Show this help:
#   sudo ./install.sh -h
###############################################################################

set -e  # Exit on error

# Script version
VERSION="1.6.0"

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
# Argument parsing
###############################################################################
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat <<EOF
LEMP Stack Installer v${VERSION}
Usage: sudo ./install.sh [OPTION]

Options:
  (no option)               Full interactive install (Nginx, PHP, DB, Composer)
  --apply-ssl               Write SSL Nginx config after certbot issues a certificate
  --reconfigure-php [VER]   Re-write Laravel PHP drop-in config for an installed PHP
                            version; auto-detects active version if VER is omitted
  --fix-permissions         Retrofit a server installed by an older version: per-user
                            PHP-FPM pool, home-dir permissions, nginx socket update
  -h, --help                Show this help message

Examples:
  sudo ./install.sh
  sudo ./install.sh --apply-ssl
  sudo ./install.sh --reconfigure-php
  sudo ./install.sh --reconfigure-php 8.4
  sudo ./install.sh --fix-permissions
EOF
    exit 0
fi

APPLY_SSL_MODE=false
if [ "${1:-}" = "--apply-ssl" ]; then
    APPLY_SSL_MODE=true
fi

FIX_PERMISSIONS_MODE=false
if [ "${1:-}" = "--fix-permissions" ]; then
    FIX_PERMISSIONS_MODE=true
fi

detect_php_version() {
    local ver
    ver=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || true)
    if [ -n "$ver" ] && [ -d "/etc/php/$ver/fpm/conf.d" ]; then
        echo "$ver"
        return
    fi
    ls -1 /etc/php/ 2>/dev/null | grep -E '^[0-9]+\.[0-9]+$' | sort -V | tail -1
}

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

if [ "$APPLY_SSL_MODE" = false ] && [ "$FIX_PERMISSIONS_MODE" = false ]; then
    if ! prompt_yes_no "Do you want to continue?" "y"; then
        print_info "Installation cancelled."
        exit 0
    fi
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
# write_ssl_nginx_config: write the full SSL Nginx config (WordPress or Laravel)
#   Args: nginx_config domain_name system_user php_socket cert_path install_wordpress
###############################################################################
write_ssl_nginx_config() {
    local nginx_config="$1"
    local domain_name="$2"
    local system_user="$3"
    local php_socket="$4"
    local cert_path="$5"
    local install_wordpress="$6"

    if [ "$install_wordpress" = true ]; then
        cat > "$nginx_config" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain_name} *.${domain_name};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${domain_name} *.${domain_name};
    root /home/${system_user}/www/current/public;

    ssl_certificate ${cert_path}/fullchain.pem;
    ssl_certificate_key ${cert_path}/privkey.pem;
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
        include snippets/fastcgi-php-realpath.conf;
        fastcgi_pass unix:${php_socket};
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINXEOF
    else
        cat > "$nginx_config" << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name ${domain_name} *.${domain_name};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ${domain_name} *.${domain_name};
    root /home/${system_user}/www/current/public;

    ssl_certificate ${cert_path}/fullchain.pem;
    ssl_certificate_key ${cert_path}/privkey.pem;
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
        include snippets/fastcgi-php-realpath.conf;
        fastcgi_pass unix:${php_socket};
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINXEOF
    fi
}

###############################################################################
# write_realpath_snippet: shared Nginx PHP handler that resolves the
# current-release symlink ($realpath_root) so OPcache caches real paths and
# new deploys take effect immediately
###############################################################################
write_realpath_snippet() {
    mkdir -p /etc/nginx/snippets
    cat > /etc/nginx/snippets/fastcgi-php-realpath.conf << 'EOF'
# Deploy-safe PHP handler — like snippets/fastcgi-php.conf but resolves the
# current-release symlink ($realpath_root) so OPcache caches real paths and
# new deploys take effect immediately. Generated by lemp-installer.
fastcgi_split_path_info ^(.+?\.php)(/.*)$;
try_files $fastcgi_script_name =404;
set $path_info $fastcgi_path_info;
fastcgi_index index.php;
include fastcgi_params;
fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
fastcgi_param DOCUMENT_ROOT $realpath_root;
fastcgi_param PATH_INFO $path_info;
EOF
    print_info "Nginx snippet written: /etc/nginx/snippets/fastcgi-php-realpath.conf"
}

###############################################################################
# write_fpm_pool_conf: dedicated PHP-FPM pool running as the deploy user.
# Nginx (www-data) can write to the socket; PHP processes run as the user,
# so storage/ and bootstrap/cache never have ownership conflicts.
#   Args: php_version system_user
###############################################################################
write_fpm_pool_conf() {
    local php_version="$1"
    local system_user="$2"

    cat > "/etc/php/${php_version}/fpm/pool.d/${system_user}.conf" << EOF
; Dedicated PHP-FPM pool for ${system_user}
; Generated by lemp-installer
[${system_user}]
user = ${system_user}
group = ${system_user}

listen = /run/php/php${php_version}-fpm-${system_user}.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.max_requests = 500

catch_workers_output = yes
EOF
    print_info "PHP-FPM pool written: /etc/php/${php_version}/fpm/pool.d/${system_user}.conf"
}

###############################################################################
# apply_ssl_nginx: apply SSL Nginx config to an existing site
###############################################################################
apply_ssl_nginx() {
    clear
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         Apply SSL Nginx Configuration                     ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    # Prompt for domain name
    local domain_name=""
    while true; do
        read -p "Enter domain name (e.g. example.com): " domain_name
        if [ -n "$domain_name" ] && validate_domain "$domain_name"; then
            break
        fi
        print_error "Invalid domain name. Please try again."
    done

    # Verify certificate exists
    local cert_path="/etc/letsencrypt/live/${domain_name}"
    if [ ! -d "$cert_path" ]; then
        print_error "No certificate found for '${domain_name}'."
        print_error "Expected path: ${cert_path}"
        echo ""
        print_info "Obtain a certificate first:"
        echo "  sudo certbot certonly --manual --preferred-challenges dns \\"
        echo "    -d '*.${domain_name}' -d '${domain_name}'"
        exit 1
    fi
    print_success "Certificate found at ${cert_path}"
    echo ""

    # Auto-detect / prompt for site name
    local site_name=""
    local available_sites
    available_sites=$(ls /etc/nginx/sites-available/ 2>/dev/null | grep -v "^default$" || true)
    if [ -n "$available_sites" ]; then
        print_info "Available Nginx sites:"
        echo "$available_sites" | nl -ba
        echo ""
    fi
    while true; do
        read -p "Enter site name: " site_name
        if [ -n "$site_name" ] && validate_site_name "$site_name"; then
            break
        fi
        print_error "Invalid site name."
    done

    # Prompt for system user
    local system_user
    system_user=$(prompt_with_default "System user" "web")

    # Auto-detect PHP FPM socket: prefer the dedicated per-user pool socket
    # (php8.3-fpm-web.sock), fall back to the stock pool socket
    local php_socket=""
    local php_sock_file
    php_sock_file=$(ls /run/php/php*-fpm-"${system_user}".sock 2>/dev/null | head -1 || true)
    if [ -z "$php_sock_file" ]; then
        php_sock_file=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -1 || true)
    fi
    if [ -n "$php_sock_file" ]; then
        php_socket="$php_sock_file"
        print_info "Detected PHP socket: ${php_socket}"
    else
        read -p "PHP FPM socket path (e.g. /run/php/php8.3-fpm-web.sock): " php_socket
    fi
    echo ""

    # Ensure certbot SSL options files exist (created by certbot-nginx plugin;
    # missing when cert was obtained via --manual certonly)
    if [ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]; then
        print_info "Creating /etc/letsencrypt/options-ssl-nginx.conf..."
        mkdir -p /etc/letsencrypt
        cat > /etc/letsencrypt/options-ssl-nginx.conf << 'EOF'
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF
    fi

    if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
        print_info "Generating /etc/letsencrypt/ssl-dhparams.pem (this may take a moment)..."
        openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048 2>/dev/null
    fi

    # Detect WordPress vs Laravel
    local install_wordpress=false
    local webroot="/home/${system_user}/www/current"
    if [ -f "${webroot}/public/wp-config.php" ] || [ -f "${webroot}/wp-config.php" ]; then
        install_wordpress=true
        print_info "WordPress installation detected."
    else
        print_info "Laravel/generic installation detected."
    fi

    # Write Nginx config (the config references the realpath snippet, so make
    # sure it exists on servers configured before v1.5.0)
    write_realpath_snippet
    local nginx_config="/etc/nginx/sites-available/${site_name}"
    print_info "Writing SSL Nginx config to ${nginx_config}..."
    write_ssl_nginx_config "$nginx_config" "$domain_name" "$system_user" "$php_socket" "$cert_path" "$install_wordpress"

    # Ensure symlink exists in sites-enabled
    if [ ! -L "/etc/nginx/sites-enabled/${site_name}" ]; then
        ln -s "$nginx_config" "/etc/nginx/sites-enabled/${site_name}"
        print_info "Created symlink: /etc/nginx/sites-enabled/${site_name}"
    fi

    # Test and reload Nginx
    echo ""
    print_step "Testing Nginx configuration..."
    if nginx -t; then
        systemctl reload nginx
        print_success "Nginx reloaded successfully!"
    else
        print_error "Nginx configuration test failed. Review ${nginx_config}."
        exit 1
    fi

    echo ""
    print_success "SSL configuration applied for ${domain_name}!"
    echo ""
    print_warning "Wildcard certificates obtained via manual DNS challenge cannot be"
    print_warning "renewed automatically. Renew manually every ~90 days:"
    echo ""
    echo "  sudo certbot certonly --manual --preferred-challenges dns \\"
    echo "    -d '*.${domain_name}' -d '${domain_name}'"
    echo ""
}

###############################################################################
# --apply-ssl early exit: skip full install flow
###############################################################################
if [ "$APPLY_SSL_MODE" = true ]; then
    apply_ssl_nginx
    exit 0
fi

###############################################################################
# --fix-permissions: retrofit a server installed by an older version
#   - dedicated PHP-FPM pool running as the deploy user
#   - home dir 750 with www-data traversal via group membership
#   - ownership/permissions of the web tree
#   - nginx configs repointed to the new socket + realpath snippet
###############################################################################
fix_permissions() {
    clear
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         Fix Permissions (per-user PHP-FPM pool)           ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo ""

    local system_user
    system_user=$(prompt_with_default "System user of the site to fix" "web")
    if ! id "$system_user" &>/dev/null || [ ! -d "/home/$system_user" ]; then
        print_error "User '$system_user' or /home/$system_user not found."
        exit 1
    fi

    local php_version
    php_version=$(detect_php_version)
    if [ -z "$php_version" ]; then
        print_error "Could not detect an installed PHP version."
        exit 1
    fi
    if [ ! -d "/etc/php/$php_version/fpm/pool.d" ]; then
        print_error "PHP-FPM pool directory not found: /etc/php/$php_version/fpm/pool.d"
        exit 1
    fi
    print_info "Using PHP $php_version"
    echo ""

    # 1. Dedicated pool. The stock www pool is left untouched in this mode —
    #    other sites on this server may still be using it.
    local pool_file="/etc/php/${php_version}/fpm/pool.d/${system_user}.conf"
    local new_socket="/run/php/php${php_version}-fpm-${system_user}.sock"
    write_fpm_pool_conf "$php_version" "$system_user"
    if ! systemctl restart "php${php_version}-fpm"; then
        print_error "php${php_version}-fpm failed to restart — removing the new pool."
        rm -f "$pool_file"
        systemctl restart "php${php_version}-fpm" || true
        print_error "Server left as it was. Check: journalctl -u php${php_version}-fpm"
        exit 1
    fi
    for _ in 1 2 3 4 5; do
        [ -S "$new_socket" ] && break
        sleep 1
    done
    if [ ! -S "$new_socket" ]; then
        print_error "Socket $new_socket did not appear. Check: journalctl -u php${php_version}-fpm"
        exit 1
    fi
    print_success "PHP-FPM pool '$system_user' running (socket: $new_socket)"

    # 2. Home dir traversal: 750 + www-data in the user's group
    usermod -aG "$system_user" www-data
    chmod 750 "/home/$system_user"
    print_success "Home dir set to 750; www-data added to group '$system_user'"

    # 3. Ownership and permissions of the web tree. Symbolic modes preserve
    #    existing execute bits (e.g. node_modules/.bin), unlike a blanket 644.
    if [ -d "/home/$system_user/www" ]; then
        print_info "Fixing ownership and permissions of /home/$system_user/www ..."
        chown -R "$system_user":"$system_user" "/home/$system_user/www"
        chmod -R u+rwX,g+rX,o+rX "/home/$system_user/www"
        [ -d "/home/$system_user/www/shared/storage" ] && chmod -R 775 "/home/$system_user/www/shared/storage"
        [ -d "/home/$system_user/www/current/storage" ] && chmod -R 775 "/home/$system_user/www/current/storage"
        [ -d "/home/$system_user/www/current/bootstrap/cache" ] && chmod -R 775 "/home/$system_user/www/current/bootstrap/cache"
        print_success "Ownership/permissions fixed"
    else
        print_warning "/home/$system_user/www not found — skipping ownership fixes."
    fi

    # 4. Nginx: realpath snippet + repoint this user's site configs
    write_realpath_snippet
    local conf changed=false
    local backups=()
    for conf in /etc/nginx/sites-available/*; do
        [ -f "$conf" ] || continue
        [ "$(basename "$conf")" = "default" ] && continue
        # Skip backups from previous runs of this mode
        case "$conf" in *.bak.*) continue ;; esac
        # Only touch configs serving this user's tree
        grep -q "root /home/${system_user}/" "$conf" || continue
        local bak
        bak="${conf}.bak.$(date +%Y%m%d%H%M%S)"
        cp -a "$conf" "$bak"
        backups+=("$conf|$bak")
        # Repoint stock socket -> per-user socket (idempotent: pattern requires "-fpm.sock")
        sed -i "s|unix:/run/php/php[0-9.]\+-fpm\.sock;|unix:${new_socket};|g" "$conf"
        # Swap the fastcgi include for the realpath variant (idempotent)
        sed -i "s|include snippets/fastcgi-php.conf;|include snippets/fastcgi-php-realpath.conf;|g" "$conf"
        changed=true
        print_info "Updated $(basename "$conf") (backup: $bak)"
    done

    if [ "$changed" = true ]; then
        if nginx -t; then
            # restart, not reload: workers must pick up the new group membership
            systemctl restart nginx
            print_success "Nginx updated and restarted."
        else
            print_error "nginx -t failed — restoring backups."
            local pair
            for pair in "${backups[@]}"; do
                cp -a "${pair#*|}" "${pair%%|*}"
            done
            nginx -t && systemctl reload nginx
            exit 1
        fi
    else
        systemctl restart nginx
        print_warning "No site configs matched root /home/${system_user}/ — nothing rewritten."
        print_info "Nginx restarted anyway so it picks up the new group membership."
    fi

    # 5. Never restructure a live flat current/ automatically — print guidance
    if [ -d "/home/$system_user/www/current" ] && [ ! -L "/home/$system_user/www/current" ]; then
        echo ""
        print_warning "'www/current' is a plain directory (pre-1.5.0 layout)."
        print_info "To migrate to the releases/shared layout manually (optional):"
        echo "  sudo su - $system_user"
        echo "  mkdir -p ~/www/releases ~/www/shared"
        echo "  # deploy a fresh release into ~/www/releases/<name>, then:"
        echo "  mv ~/www/current/.env ~/www/shared/.env"
        echo "  mv ~/www/current/storage ~/www/shared/storage"
        echo "  # link them into the release, verify it works, then:"
        echo "  rm -rf ~/www/current"
        echo "  ln -nfs ~/www/releases/<name> ~/www/current"
    fi

    echo ""
    print_success "Done. PHP now runs as '$system_user' via $new_socket"
    print_info "Artisan/composer should always run as '$system_user', never as root."
}

if [ "$FIX_PERMISSIONS_MODE" = true ]; then
    fix_permissions
    exit 0
fi

###############################################################################
# --reconfigure-php: write PHP drop-in config for installed PHP version
###############################################################################
if [ "${1:-}" = "--reconfigure-php" ]; then
    TARGET_PHP="${2:-}"

    if [ -z "$TARGET_PHP" ]; then
        TARGET_PHP=$(detect_php_version)
        if [ -z "$TARGET_PHP" ]; then
            print_error "Could not detect installed PHP version. Pass it explicitly: --reconfigure-php 8.4"
            exit 1
        fi
        print_info "Detected PHP version: $TARGET_PHP"
    fi

    if [ ! -d "/etc/php/$TARGET_PHP/fpm/conf.d" ]; then
        print_error "PHP $TARGET_PHP conf.d directory not found: /etc/php/$TARGET_PHP/fpm/conf.d"
        print_info "Available PHP versions:"
        ls /etc/php/ 2>/dev/null | grep -E '^[0-9]+\.[0-9]+$' || echo "  (none found)"
        exit 1
    fi

    print_info "Writing PHP $TARGET_PHP settings..."
    cat > "/etc/php/$TARGET_PHP/fpm/conf.d/99-laravel.ini" << 'EOF'
; Laravel-optimized PHP settings
; Generated by lemp-installer
memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 60
max_input_time = 60
date.timezone = UTC
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
EOF
    print_success "Written: /etc/php/$TARGET_PHP/fpm/conf.d/99-laravel.ini"

    WP_FOUND=$(find /etc/php/*/fpm/conf.d/99-wordpress.ini 2>/dev/null | head -1 || true)
    if [ -n "$WP_FOUND" ]; then
        print_info "Detected existing WordPress PHP settings — carrying over..."
        cat > "/etc/php/$TARGET_PHP/fpm/conf.d/99-wordpress.ini" << 'EOF'
; WordPress-specific PHP overrides
upload_max_filesize = 128M
post_max_size = 128M
max_input_vars = 3000
EOF
        print_success "Written: /etc/php/$TARGET_PHP/fpm/conf.d/99-wordpress.ini"
    fi

    if systemctl list-units --type=service 2>/dev/null | grep -q "php${TARGET_PHP}-fpm"; then
        systemctl restart "php${TARGET_PHP}-fpm"
        print_success "php${TARGET_PHP}-fpm restarted"
    else
        print_warning "php${TARGET_PHP}-fpm service not found — start it manually after installing PHP $TARGET_PHP"
    fi

    # Pools are version-scoped: after a PHP upgrade the per-user pool (v1.5.0+)
    # does not carry over automatically
    if [ -d "/etc/php/$TARGET_PHP/fpm/pool.d" ] && \
       ! ls "/etc/php/$TARGET_PHP/fpm/pool.d/"*.conf 2>/dev/null | grep -qv "/www\.conf$"; then
        print_warning "No per-user PHP-FPM pool found for PHP $TARGET_PHP."
        print_warning "If this server uses a dedicated pool, run: sudo ./install.sh --fix-permissions"
    fi

    print_success "PHP $TARGET_PHP reconfigured. Run: php -i | grep memory_limit"
    exit 0
fi

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

# PHP version — Ubuntu's default plus newer releases from ppa:ondrej/php
OS_PHP_VERSION=$(apt-cache depends php 2>/dev/null | grep -oPm1 'php\K[0-9]+\.[0-9]+' || true)
OS_PHP_VERSION="${OS_PHP_VERSION:-8.3}"
echo ""
echo "Select PHP version:"
echo "  1) ${OS_PHP_VERSION} — Ubuntu default (official repositories)"
echo "  2) 8.4 — adds ppa:ondrej/php"
echo "  3) 8.5 — adds ppa:ondrej/php"
PHP_CHOICE=""
while [[ ! "$PHP_CHOICE" =~ ^[123]$ ]]; do
    read -p "Enter your choice (1-3): " PHP_CHOICE
done
case "$PHP_CHOICE" in
    1) PHP_VERSION="$OS_PHP_VERSION" ;;
    2) PHP_VERSION="8.4" ;;
    3) PHP_VERSION="8.5" ;;
esac
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
    else
        # Browsers force HTTPS on HSTS-preloaded TLDs — plain HTTP will not open
        case "$DOMAIN_NAME" in
            *.dev|*.app|*.page)
                print_warning "The .${DOMAIN_NAME##*.} TLD is HSTS-preloaded: browsers force HTTPS and refuse plain HTTP."
                print_warning "The site will not open in a browser until SSL is added (instructions shown after install)."
                ;;
        esac
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

# PHP versions newer than the OS default come from ppa:ondrej/php
if ! apt-cache show "php${PHP_VERSION}-fpm" &> /dev/null; then
    print_info "PHP ${PHP_VERSION} is not in the Ubuntu repositories — adding ppa:ondrej/php..."
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
    if ! apt-cache show "php${PHP_VERSION}-fpm" &> /dev/null; then
        print_error "PHP ${PHP_VERSION} is not available even after adding ppa:ondrej/php."
        exit 1
    fi
fi

# Install database packages based on selection
if [ "$DATABASE_TYPE" = "mysql" ]; then
    print_info "Installing core packages (Nginx, MySQL, PHP)..."
    apt install -y nginx mysql-server "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-mysql" acl zip curl wget git unzip
else
    print_info "Installing core packages (Nginx, PostgreSQL, PHP)..."
    apt install -y nginx postgresql postgresql-contrib "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-pgsql" acl zip curl wget git unzip
fi

# Versioned package names keep the selected PHP version deterministic once the
# PPA is present (unversioned php-* meta-packages would pull the newest one).
# json is built into PHP >= 8.0 and tokenizer ships with phpX.Y-common.
print_info "Installing PHP extensions for Laravel..."
if [ "$DATABASE_TYPE" = "mysql" ]; then
    apt install -y \
        "php${PHP_VERSION}-fpm" \
        "php${PHP_VERSION}-cli" \
        "php${PHP_VERSION}-common" \
        "php${PHP_VERSION}-mysql" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-bcmath" \
        openssl \
        "php${PHP_VERSION}-intl"
else
    apt install -y \
        "php${PHP_VERSION}-fpm" \
        "php${PHP_VERSION}-cli" \
        "php${PHP_VERSION}-common" \
        "php${PHP_VERSION}-pgsql" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-xml" \
        "php${PHP_VERSION}-bcmath" \
        openssl \
        "php${PHP_VERSION}-intl"
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

    # Detect whether mysql_native_password plugin is available (removed in MySQL 8.4+)
    if mysql -e "SELECT 1 FROM information_schema.PLUGINS WHERE PLUGIN_NAME='mysql_native_password' AND PLUGIN_STATUS='ACTIVE';" 2>/dev/null | grep -q 1; then
        IDENTIFIED_WITH="IDENTIFIED WITH mysql_native_password BY '${DB_PASSWORD}'"
    else
        IDENTIFIED_WITH="IDENTIFIED BY '${DB_PASSWORD}'"
    fi

    mysql 2>"$MYSQL_ERR" <<EOF
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' ${IDENTIFIED_WITH};
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    MYSQL_EXIT=$?
    if [ $MYSQL_EXIT -ne 0 ] || [ -s "$MYSQL_ERR" ]; then
        print_error "Failed to configure MySQL user. MySQL said:"
        cat "$MYSQL_ERR" >&2
        rm -f "$MYSQL_ERR"
        exit 1
    fi
    rm -f "$MYSQL_ERR"

    # Test MySQL connection via TCP (forces password auth regardless of socket auth plugin)
    MYSQL_TEST_CNF=$(mktemp)
    chmod 600 "$MYSQL_TEST_CNF"
    # Quote the password to handle special characters in option file
    printf '[client]\nuser=%s\npassword="%s"\nhost=127.0.0.1\n' "$DB_USER" "${DB_PASSWORD//\"/\\\"}" > "$MYSQL_TEST_CNF"
    if mysql --defaults-extra-file="$MYSQL_TEST_CNF" -e "SELECT 1;" >/dev/null 2>&1; then
        rm -f "$MYSQL_TEST_CNF"
        print_success "MySQL user '$DB_USER' created and configured successfully!"
    else
        rm -f "$MYSQL_TEST_CNF"
        print_error "Failed to connect as MySQL user '$DB_USER' after creation"
        print_info "Hint: check 'mysql -u root -e \"SHOW CREATE USER ${DB_USER}@localhost\"' to inspect auth plugin"
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

# Lock down home dir; nginx (www-data) gets traversal via group membership.
# Nginx picks up the new group at the restart in Step 4.
chmod 750 /home/"$SYSTEM_USER"
usermod -aG "$SYSTEM_USER" www-data
print_info "Home dir set to 750; www-data added to group '$SYSTEM_USER'"

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

# Create site directory structure (releases/shared layout, current -> symlink).
# Everything runs as the user via su, so ownership is correct by construction.
print_info "Creating web directory structure (releases/shared layout)..."
if [ -d "/home/$SYSTEM_USER/www/current" ] && [ ! -L "/home/$SYSTEM_USER/www/current" ]; then
    print_warning "www/current already exists as a plain directory — leaving it in place."
    print_warning "Migrate to releases/shared manually (see --fix-permissions guidance) or start from a clean ~/www."
else
    su - "$SYSTEM_USER" -c "mkdir -p ~/www/releases/initial/public \
        ~/www/shared/storage/app/public \
        ~/www/shared/storage/framework/cache \
        ~/www/shared/storage/framework/sessions \
        ~/www/shared/storage/framework/views \
        ~/www/shared/storage/logs"
    su - "$SYSTEM_USER" -c "echo '<?php phpinfo(); ?>' > ~/www/releases/initial/public/index.php"
    su - "$SYSTEM_USER" -c "touch ~/www/shared/.env && chmod 640 ~/www/shared/.env"
    su - "$SYSTEM_USER" -c "chmod -R 775 ~/www/shared/storage"
    su - "$SYSTEM_USER" -c "ln -nfs ~/www/releases/initial ~/www/current"
fi

# --- PHP configuration ---
print_info "Configuring PHP ${PHP_VERSION} settings..."
PHP_INI_DROPIN="/etc/php/${PHP_VERSION}/fpm/conf.d/99-laravel.ini"
cat > "$PHP_INI_DROPIN" << 'EOF'
; Laravel-optimized PHP settings
; Generated by lemp-installer

memory_limit = 256M
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 60
max_input_time = 60
date.timezone = UTC

opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1
EOF
print_success "PHP configuration written to $PHP_INI_DROPIN"

# --- Dedicated PHP-FPM pool running as $SYSTEM_USER ---
print_info "Creating PHP-FPM pool '$SYSTEM_USER'..."
write_fpm_pool_conf "$PHP_VERSION" "$SYSTEM_USER"

# Disable the stock www pool: fresh install, nothing uses it, it wastes idle
# workers, and its socket would confuse socket auto-detection later
WWW_POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
if [ "$SYSTEM_USER" != "www" ] && [ -f "$WWW_POOL" ]; then
    mv "$WWW_POOL" "${WWW_POOL}.disabled"
    print_info "Stock www pool disabled: ${WWW_POOL}.disabled"
fi

PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm-${SYSTEM_USER}.sock"
systemctl enable php${PHP_VERSION}-fpm
if ! systemctl restart php${PHP_VERSION}-fpm; then
    print_error "php${PHP_VERSION}-fpm failed to start. Check: journalctl -u php${PHP_VERSION}-fpm"
    exit 1
fi
for _ in 1 2 3 4 5; do
    [ -S "$PHP_SOCKET" ] && break
    sleep 1
done
if [ ! -S "$PHP_SOCKET" ]; then
    print_error "PHP-FPM socket not found at $PHP_SOCKET after restart"
    exit 1
fi
print_success "PHP-FPM pool '$SYSTEM_USER' running (socket: $PHP_SOCKET)"

# Shared PHP handler snippet referenced by all server blocks below
write_realpath_snippet

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
        include snippets/fastcgi-php-realpath.conf;
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
        include snippets/fastcgi-php-realpath.conf;
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

    # Ubuntu's archive builds imagick only for the default PHP version;
    # ondrej's PPA ships a versioned build for the rest
    if apt-cache show "php${PHP_VERSION}-imagick" &> /dev/null; then
        IMAGICK_PACKAGE="php${PHP_VERSION}-imagick"
    else
        IMAGICK_PACKAGE="php-imagick"
    fi

    apt install -y \
        "php${PHP_VERSION}-gd" \
        "php${PHP_VERSION}-curl" \
        "php${PHP_VERSION}-xml" \
        "$IMAGICK_PACKAGE" \
        "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-intl"

    # WordPress-specific PHP settings
    print_info "Applying WordPress PHP settings..."
    cat > "/etc/php/${PHP_VERSION}/fpm/conf.d/99-wordpress.ini" << 'EOF'
; WordPress-specific PHP overrides
upload_max_filesize = 128M
post_max_size = 128M
max_input_vars = 3000
EOF
    print_success "WordPress PHP settings written"

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
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  WILDCARD SSL — DNS CHALLENGE INSTRUCTIONS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  Certbot will pause TWICE and ask you to add TXT DNS records."
        echo "  For each pause, follow these steps:"
        echo ""
        echo "  1. Log in to your DNS provider (Cloudflare, Route53, etc.)"
        echo "  2. Add a TXT record with:"
        echo "       Name:  _acme-challenge.${DOMAIN_NAME}"
        echo "       Value: (the value certbot shows you — it changes each time)"
        echo "       TTL:   60 (or lowest available)"
        echo ""
        echo "  3. Wait 30–120 seconds for DNS to propagate, then verify with:"
        echo "       dig TXT _acme-challenge.${DOMAIN_NAME} +short"
        echo "     (the value shown should match what certbot gave you)"
        echo ""
        echo "  4. Press Enter in certbot ONLY after the DNS value is visible"
        echo "     in the dig output above."
        echo ""
        echo "  NOTE: Certbot will ask for a SECOND record for the bare domain."
        echo "  Do NOT delete the first TXT record — add the second alongside it."
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        read -p "Press Enter when you are ready to start the DNS challenge..." _READY
        echo ""

        if certbot certonly --manual --preferred-challenges dns \
            -d "*.${DOMAIN_NAME}" -d "${DOMAIN_NAME}" \
            --agree-tos --email "$SSL_EMAIL" \
            --manual-public-ip-logging-ok 2>&1 | tee -a "$LOG_FILE"; then

            print_success "Wildcard certificate obtained!"

            NGINX_CONFIG="/etc/nginx/sites-available/$SITE_NAME"
            CERT_PATH="/etc/letsencrypt/live/${DOMAIN_NAME}"

            write_ssl_nginx_config "$NGINX_CONFIG" "$DOMAIN_NAME" "$SYSTEM_USER" "$PHP_SOCKET" "$CERT_PATH" "$INSTALL_WORDPRESS"

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
echo "Web root:             /home/$SYSTEM_USER/www/current/public (current -> releases/initial)"
echo "Shared dir:           /home/$SYSTEM_USER/www/shared (storage, .env)"
echo "Nginx config:         /etc/nginx/sites-available/$SITE_NAME"
echo "PHP version:          $PHP_VERSION"
echo "PHP-FPM pool:         $SYSTEM_USER (runs as $SYSTEM_USER)"
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
    else
        echo "SSL:                  Not configured"
    fi
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [ -n "$DOMAIN_NAME" ] && [ "$INSTALL_SSL" = false ]; then
    print_warning "SSL is not configured. To add it later:"
    echo "  sudo snap install --classic certbot"
    echo "  sudo ln -sf /snap/bin/certbot /usr/bin/certbot"
    echo "  sudo certbot --nginx -d $DOMAIN_NAME"
    case "$DOMAIN_NAME" in
        *.dev|*.app|*.page)
            print_warning "Browsers force HTTPS on the .${DOMAIN_NAME##*.} TLD — the site will NOT open in a browser until SSL is added."
            ;;
    esac
    echo ""
fi
print_info "Next steps for Laravel deployment (releases/shared layout):"
echo ""
echo "  1. Switch to web user (always deploy as $SYSTEM_USER, never as root):"
echo "     sudo su - $SYSTEM_USER"
echo ""
echo "  2. Clone your first release:"
echo "     cd ~/www/releases"
echo "     git clone YOUR_REPO release-1 && cd release-1"
echo ""
echo "  3. Install dependencies:"
echo "     composer install --no-dev --optimize-autoloader"
echo ""
echo "  4. Link shared resources into the release:"
echo "     rm -rf storage && ln -nfs ~/www/shared/storage storage"
echo "     ln -nfs ~/www/shared/.env .env"
echo ""
echo "  5. Configure environment (lives in shared/, survives deploys):"
echo "     cp .env.example ~/www/shared/.env"
echo "     nano ~/www/shared/.env"
echo ""
echo "  6. Run Laravel setup (as $SYSTEM_USER — root-owned caches break PHP-FPM):"
echo "     php artisan key:generate"
echo "     php artisan storage:link"
echo "     php artisan migrate --force"
echo "     php artisan config:cache && php artisan route:cache && php artisan view:cache"
echo ""
echo "  7. Activate the release:"
echo "     ln -nfs ~/www/releases/release-1 ~/www/current"
echo ""
echo "  8. Restart queue workers (if any):"
echo "     php artisan queue:restart"
echo ""
echo "  Subsequent deploys: repeat 2-4 and 6-8 with a new release name (e.g. a"
echo "  timestamp), then remove old releases when disk fills up."
echo ""
echo "  Permissions are automatic: PHP-FPM runs as '$SYSTEM_USER', so no chmod or"
echo "  chown is ever needed after a deploy."
echo ""
print_info "Optional — queue workers via Supervisor:"
echo ""
echo "  sudo apt install supervisor"
echo "  # then create /etc/supervisor/conf.d/laravel-worker.conf:"
echo ""
echo "  [program:laravel-worker]"
echo "  process_name=%(program_name)s_%(process_num)02d"
echo "  command=php /home/$SYSTEM_USER/www/current/artisan queue:work --sleep=3 --tries=3 --max-time=3600"
echo "  autostart=true"
echo "  autorestart=true"
echo "  stopasgroup=true"
echo "  killasgroup=true"
echo "  user=$SYSTEM_USER"
echo "  numprocs=2"
echo "  redirect_stderr=true"
echo "  stdout_logfile=/home/$SYSTEM_USER/www/shared/storage/logs/worker.log"
echo "  stopwaitsecs=3600"
echo ""
echo "  sudo supervisorctl reread && sudo supervisorctl update"
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

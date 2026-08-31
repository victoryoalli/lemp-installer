# LEMP Stack Installer for Ubuntu 24.04

<div align="center">

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![PHP](https://img.shields.io/badge/php-8.3--8.5-%23777BB4.svg?style=for-the-badge&logo=php&logoColor=white)
![Laravel](https://img.shields.io/badge/laravel-%23FF2D20.svg?style=for-the-badge&logo=laravel&logoColor=white)

**Automated LEMP stack installation script optimized for Laravel**

[Installation](#-quick-start) • [Documentation](#-documentation) • [Features](#-features) • [Contributing](#-contributing)

</div>

---

## 🚀 Quick Start

### One-line installation:

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh | sudo bash
```

### Or download and review first (recommended):

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

---

## ✨ Features

- 🎯 **Interactive installation** with sensible defaults
- 🗄️ **Database choice**: MySQL 8.0+ or PostgreSQL 15+
- 🐘 **PHP version choice**: Ubuntu's default 8.3, or 8.4 / 8.5 (`ppa:ondrej/php` added automatically)
- 🔒 **SSL/TLS** configuration with Let's Encrypt
- 👤 **System user** setup for deployments
- 🧑‍🔧 **Per-user PHP-FPM pool** — PHP runs as the deploy user, so `storage/` and `bootstrap/cache` never have permission conflicts (no `chmod` after deploys)
- 🚀 **Releases/shared deploy layout** — `current` is a symlink to a release; `storage/` and `.env` live in `shared/` and survive deploys; Nginx uses `$realpath_root` so OPcache never serves stale code after a release flip
- 🔑 **SSH keys** generation for GitHub/GitLab integration
- 🛡️ **UFW firewall** configuration (optional)
- 📦 **Composer** installed automatically
- 🌐 **WordPress support** (optional)
- ⚙️ **Laravel-optimized PHP settings** — memory, upload limits, OPcache, and timezone configured automatically
- 📝 **Secure logging** — log file is restricted to root (mode 600)
- ✅ **Automatic validation** and health checks
- 🔐 **Input validation** — usernames, site names, and domain names are validated before use

---

## 📦 What Gets Installed

| Component | Version | Description |
|-----------|---------|-------------|
| **Nginx** | Latest | High-performance web server |
| **MySQL** | 8.0+ | Relational database (choose one) |
| **PostgreSQL** | 15+ | Relational database (choose one) |
| **PHP** | 8.3 / 8.4 / 8.5 | PHP-FPM with essential extensions (you pick the version; 8.4/8.5 come from `ppa:ondrej/php`) |
| **Composer** | Latest | PHP dependency manager |
| **Certbot** | Latest | SSL certificate automation |
| **UFW** | Latest | Uncomplicated Firewall |

### PHP Extensions Included:

Installed as versioned packages for the PHP version you pick (`php8.4-fpm`, `php8.4-mysql`, …):

- fpm, cli, common
- mysql (MySQL) or pgsql (PostgreSQL), zip, gd
- mbstring, curl, xml
- bcmath, intl, openssl

### Optional WordPress Extensions:

- imagick (plus gd, curl, xml, mbstring, zip, intl)

---

## 📋 Requirements

- Ubuntu 24.04 (recommended) or 22.04
- Root access or sudo privileges
- Stable internet connection
- Domain name pointing to server IP (optional, for SSL)
- SSH public key (optional, for remote access)

---

## 🔧 Installation Process

The script will prompt you for:

1. **Database Selection**
   - Choose MySQL 8.0+ or PostgreSQL 15+

2. **Database Configuration**
   - Username (validated: lowercase letters, numbers, `_` or `-`, max 32 chars)
   - Password (required, with confirmation)

3. **System User**
   - Username (same validation rules as database username)

4. **Site Configuration**
   - Site name (letters, numbers, `_` or `-`)
   - Domain name (optional, validated format)

5. **PHP Version**
   - Ubuntu's default 8.3, or a newer release (8.4, 8.5)
   - Newer versions add `ppa:ondrej/php` automatically during install

6. **Optional Features**
   - WordPress packages
   - SSL with Let's Encrypt (standard or wildcard)
   - SSH key generation
   - UFW firewall setup

---

## 📁 Directory Structure

```
/home/web/                       (mode 750; www-data traverses via group)
├── www/
│   ├── current -> releases/initial   (symlink, flipped on each deploy)
│   ├── releases/
│   │   └── initial/
│   │       └── public/
│   │           └── index.php (phpinfo test)
│   └── shared/
│       ├── storage/             (Laravel storage, shared across releases)
│       └── .env                 (environment file, shared across releases)
└── .ssh/
    ├── authorized_keys
    ├── id_ed25519
    └── id_ed25519.pub

/etc/nginx/
├── sites-available/
│   └── mysite
└── snippets/
    └── fastcgi-php-realpath.conf    (PHP handler using $realpath_root)

/etc/php/8.3/fpm/pool.d/
└── web.conf                     (PHP-FPM pool running as user "web")

/var/log/
└── lemp-install-YYYYMMDD-HHMMSS.log
```

PHP-FPM runs as the deploy user (`web`) through a dedicated pool listening on `/run/php/php8.3-fpm-web.sock`. Nginx keeps running as `www-data` — it only serves static files and forwards requests to the socket.

---

## 🎯 Post-Installation

### 1. Verify Services

```bash
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status php8.3-fpm
```

### 2. Test PHP

Visit `http://your-domain.com` or `http://your-server-ip` in your browser.

### 3. Create Database

**MySQL:**
```bash
mysql -u web -p
```

```sql
CREATE DATABASE my_app;
SHOW DATABASES;
EXIT;
```

**PostgreSQL:**
```bash
psql -h localhost -U web -d postgres
```

```sql
CREATE DATABASE my_app;
\l
\q
```

---

## 🚢 Laravel Deployment

Deploys use the releases/shared layout: each deploy is a fresh directory under `~/www/releases/`, `storage/` and `.env` live in `~/www/shared/` and are symlinked into every release, and `~/www/current` is a symlink flipped to activate a release.

> **Always deploy as the `web` user, never as root.** PHP-FPM runs as `web`, so files created by root (artisan caches, logs) would break the site.

### Step 1: Clone a Release

```bash
sudo su - web
cd ~/www/releases
git clone git@github.com:username/repo.git release-1
cd release-1
```

### Step 2: Install Dependencies

```bash
composer install --no-dev --optimize-autoloader
```

### Step 3: Link Shared Resources and Configure Laravel

```bash
rm -rf storage && ln -nfs ~/www/shared/storage storage
ln -nfs ~/www/shared/.env .env

cp .env.example ~/www/shared/.env
nano ~/www/shared/.env
```

Edit `.env` file:

**MySQL:**
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=my_app
DB_USERNAME=web
DB_PASSWORD=your_password
```

**PostgreSQL:**
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5432
DB_DATABASE=my_app
DB_USERNAME=web
DB_PASSWORD=your_password
```

### Step 4: Run Laravel Commands

```bash
php artisan key:generate
php artisan storage:link
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Step 5: Activate the Release

```bash
ln -nfs ~/www/releases/release-1 ~/www/current
php artisan queue:restart   # if you run queue workers
```

No `chmod` or `chown` is needed: PHP-FPM runs as `web`, the same user that deploys.

For the next deploy, repeat steps 1–5 with a new release name (a timestamp works well), then delete old releases when you no longer need them for rollback.

### Optional: Queue Workers with Supervisor

```bash
sudo apt install supervisor
sudo nano /etc/supervisor/conf.d/laravel-worker.conf
```

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /home/web/www/current/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=web
numprocs=2
redirect_stderr=true
stdout_logfile=/home/web/www/shared/storage/logs/worker.log
stopwaitsecs=3600
```

```bash
sudo supervisorctl reread && sudo supervisorctl update
```

The worker must run as `web` (`user=web`): a worker running as another user would create log files the web processes can't write to. After each deploy, `php artisan queue:restart` makes workers pick up the new code.

---

## 🛠️ Useful Commands

### Nginx

```bash
sudo nginx -t                          # Test configuration
sudo systemctl reload nginx            # Reload config
sudo systemctl restart nginx           # Restart service
sudo tail -f /var/log/nginx/error.log  # View error logs
```

### PHP-FPM

```bash
sudo systemctl restart php8.3-fpm      # Restart service
sudo systemctl status php8.3-fpm       # Check status
```

### MySQL

```bash
mysql -u web -p                                # Login to MySQL
mysqldump -u web -p db > backup.sql            # Backup database
mysql -u web -p db < backup.sql                # Restore database
sudo systemctl status mysql                    # Check MySQL status
```

### PostgreSQL

```bash
psql -h localhost -U web -d postgres           # Login to PostgreSQL
pg_dump -h localhost -U web db > backup.sql    # Backup database
psql -h localhost -U web db < backup.sql       # Restore database
sudo systemctl status postgresql               # Check PostgreSQL status
```

### SSL (Certbot)

```bash
sudo certbot renew                     # Renew certificates
sudo certbot renew --dry-run           # Test renewal
sudo certbot certificates              # List certificates
```

#### Wildcard Certificates (DNS Challenge)

When you select **Wildcard SSL** during installation, the installer issues a certificate for `*.yourdomain.com` and `yourdomain.com` using Let's Encrypt's DNS-01 challenge. Certbot will **pause twice** and ask you to add TXT DNS records.

**Before running the installer, have your DNS provider's control panel open and ready.**

For each pause certbot makes:

1. Add a **TXT record** to your DNS:

   | Field | Value |
   |-------|-------|
   | **Name** | `_acme-challenge.yourdomain.com` |
   | **Value** | (the string certbot displays — it changes each time) |
   | **TTL** | `60` (or the lowest your provider allows) |

2. Verify propagation before pressing Enter in certbot:

   ```bash
   dig TXT _acme-challenge.yourdomain.com +short
   ```

   The output must match the value certbot gave you. If it doesn't, wait 30–120 seconds and try again.

3. Press Enter in certbot **only after** the correct value appears in `dig`.

> **Important:** When certbot asks for the **second** TXT record, do **not** delete the first one — add the second record alongside it.

**Renewal:** Wildcard certificates obtained via manual DNS challenge cannot be renewed automatically. Renew manually every ~90 days:

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d '*.yourdomain.com' -d 'yourdomain.com'
```

After renewal, reload Nginx to pick up the new certificate files:

```bash
sudo systemctl reload nginx
```

> **Note:** You do not need to run `--apply-ssl` again on renewal. The Nginx configuration stays the same — only the certificate files change. `--apply-ssl` is a one-time setup step.

#### Applying SSL config after certificate issuance

Once certbot has successfully issued your wildcard certificate, run:

```bash
sudo ./install.sh --apply-ssl
```

The script will ask for your domain and site name, then write the full SSL Nginx configuration and reload Nginx automatically.

---

### Getting help

```bash
sudo ./install.sh -h
```

Prints all available modes and usage examples.

---

### ⚙️ Reconfiguring PHP settings

After a full install, or after upgrading to a new PHP version, you can re-apply the Laravel-optimized PHP settings without running the full installer:

```bash
# Auto-detect installed PHP version
sudo ./install.sh --reconfigure-php

# Or specify a version explicitly
sudo ./install.sh --reconfigure-php 8.4
```

This writes (or overwrites) `/etc/php/<version>/fpm/conf.d/99-laravel.ini` with:

| Setting | Value |
|---------|-------|
| `memory_limit` | 256M |
| `upload_max_filesize` | 64M |
| `post_max_size` | 64M |
| `max_execution_time` | 60 |
| `date.timezone` | UTC |
| OPcache | enabled, 128M, 10k files |

If a `99-wordpress.ini` file exists from a previous install, it is carried over automatically. The PHP-FPM service is restarted if it's running.

---

### 🔧 Fixing permissions on an existing server

If your server was set up with an older version of this script (PHP-FPM running as `www-data`, flat `current/` directory), you can retrofit the new permission model without reinstalling:

```bash
sudo ./install.sh --fix-permissions
```

This mode:

- Creates the dedicated PHP-FPM pool running as your deploy user (e.g. `web`)
- Sets `/home/web` to `750` and adds `www-data` to the `web` group so Nginx can traverse it
- Fixes ownership (`web:web`) and permissions of `~/www` (dirs 755, files 644, `storage` 775)
- Repoints your Nginx site configs to the new socket and the `$realpath_root` snippet (backups are created; changes are rolled back automatically if `nginx -t` fails)
- Restarts PHP-FPM and Nginx

It never touches the stock `www` pool (other sites may use it) and never restructures a flat `current/` directory into `releases/` — it prints manual migration steps instead.

---

## 🐛 Troubleshooting

### 502 Bad Gateway

**Issue:** PHP-FPM not running or wrong socket path

```bash
sudo systemctl restart php8.3-fpm
ls -la /run/php/php8.3-fpm-web.sock   # per-user pool socket (v1.5.0+)
```

The socket must be owned by `www-data:www-data` with mode `0660`. If your Nginx config still points to the old `/run/php/php8.3-fpm.sock`, run `sudo ./install.sh --fix-permissions`.

### 403 Forbidden

**Issue:** Nginx (`www-data`) can't traverse `/home/web`

The home directory is `750` and `www-data` reaches the web root through membership in the `web` group. Verify and repair:

```bash
id www-data                        # must list "web" among the groups
sudo usermod -aG web www-data      # if missing
sudo chmod 750 /home/web
sudo systemctl restart nginx       # restart (not reload) to pick up the group
```

You should **not** need `chmod 755 /home/web` or any `chmod -R 775` on the project — if you do, PHP-FPM is probably not running as `web` (run `--fix-permissions`).

### Database Connection Error

**Issue:** Wrong credentials or permissions

```bash
mysql -u root -p
```

```sql
GRANT ALL PRIVILEGES ON *.* TO 'web'@'localhost';
FLUSH PRIVILEGES;
```

---

## 🔒 Security

### Script Security Hardening

The installer includes several security measures:

- **Log file protection** — the install log is created with mode `600` (root-readable only) before any output is written to it
- **Input validation** — usernames, site names, and domain names are validated against strict patterns to prevent shell injection and SQL injection
- **MySQL password safety** — the connection test uses a temporary `.my.cnf` config file rather than passing the password on the command line, preventing it from appearing in `ps aux` output
- **PostgreSQL identifier quoting** — the database username is double-quoted in SQL (`"username"`) to prevent SQL injection via a crafted username
- **PostgreSQL connection verification** — the post-creation test connects as the newly created user (not as the `postgres` superuser) to confirm the user was actually created correctly
- **SSH key safety** — the public key is piped via stdin rather than embedded in a shell string, preventing injection via keys containing single quotes

### Post-Installation Best Practices

### 1. Change SSH Port

```bash
sudo nano /etc/ssh/sshd_config
# Change: Port 22 -> Port 2222
sudo systemctl restart sshd
```

### 2. Disable Root Login

```bash
sudo nano /etc/ssh/sshd_config
# Change: PermitRootLogin yes -> PermitRootLogin no
sudo systemctl restart sshd
```

### 3. Install Fail2Ban

```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 4. Regular Updates

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 📚 Documentation

- [Installation Guide](docs/installation.md)
- [Laravel Deployment](docs/laravel-deployment.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Security Guide](docs/security.md)
- [FAQ](docs/faq.md)
- [Manual Test Plan](docs/testing.md) (for contributors)

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Based on the guide at [victoryoalli.me/ubuntu-lemp-install](https://victoryoalli.me/ubuntu-lemp-install)
- Inspired by the Laravel and Ubuntu communities

---

## 📞 Support

- 🌐 Website: [victoryoalli.me](https://victoryoalli.me)
- 📝 Blog: [victoryoalli.me/ubuntu-lemp-install](https://victoryoalli.me/ubuntu-lemp-install)
- 🐛 Issues: [GitHub Issues](https://github.com/victoryoalli/lemp-installer/issues)

---

## ⭐ Star History

If this project helped you, please consider giving it a ⭐!

[![Star History Chart](https://api.star-history.com/svg?repos=victoryoalli/lemp-installer&type=Date)](https://star-history.com/#victoryoalli/lemp-installer&Date)

---

<div align="center">

Made with ❤️ by [Victor Yoalli](https://victoryoalli.me)

</div>

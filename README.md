# LEMP Stack Installer for Ubuntu 24.04

<div align="center">

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/postgresql-%23316192.svg?style=for-the-badge&logo=postgresql&logoColor=white)
![PHP](https://img.shields.io/badge/php-8.3-%23777BB4.svg?style=for-the-badge&logo=php&logoColor=white)
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
- 🔒 **SSL/TLS** configuration with Let's Encrypt
- 👤 **System user** setup for deployments
- 🔑 **SSH keys** generation for GitHub/GitLab integration
- 🛡️ **UFW firewall** configuration (optional)
- 📦 **Composer** installed automatically
- 🌐 **WordPress support** (optional)
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
| **PHP** | 8.3 | PHP-FPM with essential extensions |
| **Composer** | Latest | PHP dependency manager |
| **Certbot** | Latest | SSL certificate automation |
| **UFW** | Latest | Uncomplicated Firewall |

### PHP Extensions Included:

- php-fpm, php-cli, php-common
- php-mysql (MySQL) or php-pgsql (PostgreSQL), php-zip, php-gd
- php-mbstring, php-curl, php-xml
- php-bcmath, php-tokenizer, openssl

### Optional WordPress Extensions:

- php-dom, php-imagick, php-intl

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

5. **Optional Features**
   - WordPress packages
   - SSL with Let's Encrypt (standard or wildcard)
   - SSH key generation
   - UFW firewall setup

---

## 📁 Directory Structure

```
/home/web/
├── www/
│   └── current/
│       └── public/
│           └── index.php (phpinfo test)
└── .ssh/
    ├── authorized_keys
    ├── id_ed25519
    └── id_ed25519.pub

/etc/nginx/
└── sites-available/
    └── mysite

/var/log/
└── lemp-install-YYYYMMDD-HHMMSS.log
```

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

### Step 1: Clone Your Repository

```bash
sudo su - web
cd ~/www
git clone git@github.com:username/repo.git current
cd current
```

### Step 2: Install Dependencies

```bash
composer install --no-dev --optimize-autoloader
```

### Step 3: Configure Laravel

```bash
cp .env.example .env
nano .env
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
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan storage:link
```

### Step 5: Set Permissions

```bash
chmod -R 775 storage bootstrap/cache
```

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

## 🐛 Troubleshooting

### 502 Bad Gateway

**Issue:** PHP-FPM not running

```bash
sudo systemctl restart php8.3-fpm
ls -la /run/php/php8.3-fpm.sock
```

### 403 Forbidden

**Issue:** Incorrect permissions

```bash
sudo chmod 755 /home/web
sudo chmod -R 775 /home/web/www/current/storage
```

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

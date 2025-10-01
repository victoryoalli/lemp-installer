# LEMP Stack Installer for Ubuntu 24.04

<div align="center">

![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![Nginx](https://img.shields.io/badge/nginx-%23009639.svg?style=for-the-badge&logo=nginx&logoColor=white)
![MySQL](https://img.shields.io/badge/mysql-%2300f.svg?style=for-the-badge&logo=mysql&logoColor=white)
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
- 🔒 **SSL/TLS** configuration with Let's Encrypt
- 👤 **System user** setup for deployments
- 🔑 **SSH keys** generation for GitHub/GitLab integration
- 🛡️ **UFW firewall** configuration (optional)
- 📦 **Composer** installed automatically
- 🌐 **WordPress support** (optional)
- 📝 **Detailed logging** of installation process
- ✅ **Automatic validation** and health checks

---

## 📦 What Gets Installed

| Component | Version | Description |
|-----------|---------|-------------|
| **Nginx** | Latest | High-performance web server |
| **MySQL** | 8.0+ | Database management system |
| **PHP** | 8.3 | PHP-FPM with essential extensions |
| **Composer** | Latest | PHP dependency manager |
| **Certbot** | Latest | SSL certificate automation |
| **UFW** | Latest | Uncomplicated Firewall |

### PHP Extensions Included:

- php-fpm, php-cli, php-common
- php-mysql, php-zip, php-gd
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

1. **MySQL Configuration**
   - Username (default: `web`)
   - Password (required, with confirmation)

2. **System User**
   - Username (default: `web`)

3. **Site Configuration**
   - Site name (default: `mysite`)
   - Domain name (optional)

4. **Optional Features**
   - WordPress packages
   - SSL with Let's Encrypt
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

```bash
mysql -u web -p
```

```sql
CREATE DATABASE my_app;
SHOW DATABASES;
EXIT;
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

```env
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_DATABASE=my_app
DB_USERNAME=web
DB_PASSWORD=your_mysql_password
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
mysql -u web -p                        # Login to MySQL
mysqldump -u web -p db > backup.sql    # Backup database
mysql -u web -p db < backup.sql        # Restore database
```

### SSL (Certbot)

```bash
sudo certbot renew                     # Renew certificates
sudo certbot renew --dry-run           # Test renewal
sudo certbot certificates              # List certificates
```

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

## 🔒 Security Best Practices

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

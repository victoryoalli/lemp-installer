# Installation Guide

Complete guide to installing the LEMP stack (Nginx, MySQL/PostgreSQL, PHP 8.3, Composer) optimized for Laravel on Ubuntu 24.04.

## Requirements

- Ubuntu 24.04 (recommended) or 22.04
- Root access or sudo privileges
- Stable internet connection
- Domain name pointing to the server IP (optional, required for SSL)
- SSH public key (optional, for remote access as the deploy user)

## Quick Start

One-line installation:

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh | sudo bash
```

Or download and review first (recommended):

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh -o install.sh
chmod +x install.sh
sudo ./install.sh
```

## What Gets Installed

| Component | Version | Notes |
|-----------|---------|-------|
| Nginx | Latest | Runs as `www-data`, serves static files and proxies PHP |
| MySQL **or** PostgreSQL | 8.0+ / 15+ | You choose one during install |
| PHP-FPM | 8.3 | Runs as your deploy user through a dedicated pool |
| Composer | Latest | PHP dependency manager |
| Certbot | Latest | Only if you enable SSL |
| UFW | Latest | Only if you enable the firewall |

## What the Installer Prompts For

1. **Database**: MySQL or PostgreSQL, plus a database username and password.
2. **System user**: the deploy user (default `web`). It owns `/home/web/www` and is the user PHP-FPM runs as.
3. **Site**: a site name (for the Nginx config filename) and an optional domain name.
4. **Optional features**: WordPress packages, SSL (standard or wildcard), SSH key generation, UFW firewall.

A summary is shown before anything is installed.

## What the Installer Sets Up

### Permission model (v1.5.0+)

- A dedicated PHP-FPM pool at `/etc/php/8.3/fpm/pool.d/web.conf` runs PHP **as the deploy user** (`web`), listening on `/run/php/php8.3-fpm-web.sock`. The socket is owned by `www-data:www-data` with mode `0660` so Nginx can reach it. The stock `www` pool is disabled (renamed `www.conf.disabled`).
- `/home/web` is set to `750`, and `www-data` is added to the `web` group so Nginx can traverse the directory.
- Because PHP and deploys use the same user, no `chmod`/`chown` is ever needed after a deploy.

### Directory layout

```
/home/web/www/
├── current -> releases/initial    (symlink, flipped on each deploy)
├── releases/
│   └── initial/public/index.php   (phpinfo placeholder)
└── shared/
    ├── storage/                   (Laravel storage, shared across releases)
    └── .env                       (environment file, shared across releases)
```

### Nginx

The server block's `root` is `/home/web/www/current/public`. PHP requests go through `/etc/nginx/snippets/fastcgi-php-realpath.conf`, which sets `SCRIPT_FILENAME` from `$realpath_root` — OPcache caches the resolved release path, so a new deploy takes effect the moment the `current` symlink flips, without restarting PHP-FPM.

### PHP settings

`/etc/php/8.3/fpm/conf.d/99-laravel.ini`: `memory_limit=256M`, `upload_max_filesize=64M`, `post_max_size=64M`, `max_execution_time=60`, `date.timezone=UTC`, OPcache enabled. WordPress installs also get `99-wordpress.ini` (`128M` uploads, `max_input_vars=3000`).

## Modes

| Command | Purpose |
|---------|---------|
| `sudo ./install.sh` | Full interactive install |
| `sudo ./install.sh --apply-ssl` | Write the SSL Nginx config after certbot issues a certificate |
| `sudo ./install.sh --reconfigure-php [VER]` | Re-apply the PHP drop-in settings (e.g. after a PHP upgrade) |
| `sudo ./install.sh --fix-permissions` | Retrofit a server installed by an older version to the v1.5.0 permission model |
| `sudo ./install.sh -h` | Show usage |

### `--fix-permissions` in detail

For servers set up before v1.5.0 (PHP-FPM as `www-data`, flat `current/` directory). It:

- Creates the per-user PHP-FPM pool and verifies the socket appears (rolls back the pool if PHP-FPM fails to restart)
- Sets `/home/<user>` to `750` and adds `www-data` to the user's group
- Fixes ownership (`user:user`) and permissions of `~/www` (directories `755`, files `644`, `storage` `775`)
- Repoints the user's Nginx site configs to the new socket and the `$realpath_root` snippet — every modified file is backed up first, and all changes are restored automatically if `nginx -t` fails
- Restarts PHP-FPM and Nginx

It deliberately does **not** touch the stock `www` pool (other sites may depend on it) and does **not** restructure a flat `current/` directory — it prints manual migration steps instead.

## Logs

Each run writes a full log to `/var/log/lemp-install-YYYYMMDD-HHMMSS.log`, created with mode `600` (root-only) before any sensitive output is written.

## After Installation

Visit `http://your-server-ip` (or your domain) — you should see the `phpinfo()` placeholder page served from the initial release. Then follow the [Laravel Deployment guide](laravel-deployment.md).

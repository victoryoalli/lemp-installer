# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-01

### Added
- Initial release of LEMP Stack installer
- Interactive installation with sensible defaults
- Nginx web server installation and configuration
- MySQL 8.0+ database server setup
- PHP 8.3 with FPM and essential extensions
- Composer dependency manager installation
- SSL/TLS configuration with Let's Encrypt (Certbot)
- System user creation for deployments
- SSH key generation for GitHub/GitLab integration
- UFW firewall configuration (optional)
- WordPress package support (optional)
- Detailed installation logging
- Automatic service validation
- Password confirmation for MySQL
- Ubuntu version detection and validation
- Comprehensive error handling
- Post-installation instructions
- Configuration summary before installation

### Security
- Password confirmation requirement for MySQL
- SSH key-based authentication setup
- UFW firewall rules for Nginx and SSH
- Secure file permissions for web directories
- Root login recommendations in documentation

### Documentation
- Comprehensive README with badges
- Quick start guide
- Installation process documentation
- Laravel deployment guide
- Troubleshooting section
- Security best practices
- Useful commands reference
- Contributing guidelines

## [1.4.0] - 2026-02-25

### Added
- Laravel-optimized PHP drop-in config written to `/etc/php/<version>/fpm/conf.d/99-laravel.ini` on every full install (`memory_limit=256M`, `upload_max_filesize=64M`, `post_max_size=64M`, `max_execution_time=60`, `date.timezone=UTC`, OPcache enabled)
- WordPress installs now also write `/etc/php/<version>/fpm/conf.d/99-wordpress.ini` (`upload_max_filesize=128M`, `post_max_size=128M`, `max_input_vars=3000`)
- `--reconfigure-php [version]` mode — re-applies PHP drop-in settings for an installed PHP version without running the full installer; auto-detects the active version when no argument is given; carries over WordPress settings if present
- `-h` / `--help` flag — prints usage, all available modes with examples, and exits cleanly

## [1.5.0] - 2026-07-20

### Added
- Dedicated PHP-FPM pool running as the deploy user (`/etc/php/<version>/fpm/pool.d/<user>.conf`, socket `/run/php/php<version>-fpm-<user>.sock` owned by `www-data:www-data` mode `0660`) — PHP writes to `storage/` and `bootstrap/cache` as the same user that deploys, eliminating permission conflicts
- Releases/shared deploy layout: `~/www/current` is now a symlink to `~/www/releases/<name>`; `storage/` and `.env` live in `~/www/shared/` and are symlinked into each release
- Shared Nginx snippet `/etc/nginx/snippets/fastcgi-php-realpath.conf` used by all generated server blocks
- `--fix-permissions` mode — retrofits servers installed by older versions: creates the per-user pool, fixes home-dir permissions and group membership, fixes ownership/permissions of `~/www`, and repoints Nginx site configs to the new socket (with backups and automatic rollback if `nginx -t` fails)
- Post-install instructions now include an example Supervisor config for Laravel queue workers running as the deploy user

### Changed
- Nginx PHP handler sets `SCRIPT_FILENAME`/`DOCUMENT_ROOT` from `$realpath_root`, so OPcache resolves real release paths and new deploys take effect immediately after the `current` symlink flip
- Home directory is now `750` with `www-data` added to the deploy user's group (previously `755` world-traversable)
- Stock `www` PHP-FPM pool is disabled on fresh installs (renamed to `www.conf.disabled`); `--fix-permissions` leaves it untouched
- `--apply-ssl` socket auto-detection now prefers the per-user pool socket (`php*-fpm-<user>.sock`) before falling back to the stock socket
- Post-install deployment instructions rewritten for the releases/shared workflow (deploy as the user, never as root)
- `--reconfigure-php` warns when the target PHP version has no per-user pool (e.g. after a PHP upgrade) and suggests running `--fix-permissions`

### Fixed
- "Permission denied" errors on `storage/` and `bootstrap/cache` after deploys (PHP-FPM previously ran as `www-data` while files belonged to the deploy user)
- Stale code served by OPcache after symlink-based deploys

## [1.6.0] - 2026-08-31

### Added
- PHP version selection during install: choose the Ubuntu default (8.3) or a newer release (8.4, 8.5); `ppa:ondrej/php` is added automatically only when the chosen version is not in the OS repositories

### Changed
- PHP packages are installed with explicit version names (`php8.4-fpm`, `php8.4-mysql`, …) instead of the unversioned meta-packages, so the selected version stays deterministic even with extra repositories present
- Dropped `php-json` and `php-tokenizer` from the package list — JSON is built into PHP ≥ 8.0 and tokenizer ships with `phpX.Y-common`
- WordPress installs use `phpX.Y-imagick` when available (ondrej PPA), falling back to `php-imagick` (Ubuntu builds imagick only for the default PHP)

## [Unreleased]

### Planned Features
- PostgreSQL option alongside MySQL
- Redis installation option
- Node.js and npm installation
- Automated backup configuration
- Monitoring tools integration (optional)
- Docker support
- Multi-site configuration
- Database optimization presets

### Planned Improvements
- Non-interactive mode with configuration file
- Rollback mechanism
- Health check after installation
- Automated testing with GitHub Actions
- Support for Ubuntu 22.04 LTS
- Custom PHP extensions selection
- Email configuration (SMTP)
- Cron job setup for Laravel scheduler

---

## Version History

### Version Numbering
- **Major version (X.0.0)**: Breaking changes or major feature additions
- **Minor version (1.X.0)**: New features, backward compatible
- **Patch version (1.0.X)**: Bug fixes and minor improvements

### How to Upgrade
```bash
# Download latest version
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/main/install.sh -o install.sh

# Review changes
cat install.sh

# Run installation (will update existing components)
sudo ./install.sh
```

---

## Contributing

Found a bug or have a feature request? Please check our [Contributing Guidelines](CONTRIBUTING.md) and open an issue or pull request.

---

[1.0.0]: https://github.com/victoryoalli/lemp-installer/releases/tag/v1.0.0
[1.4.0]: https://github.com/victoryoalli/lemp-installer/compare/v1.0.0...v1.4.0
[1.5.0]: https://github.com/victoryoalli/lemp-installer/compare/v1.4.0...v1.5.0
[1.6.0]: https://github.com/victoryoalli/lemp-installer/compare/v1.5.0...v1.6.0
[Unreleased]: https://github.com/victoryoalli/lemp-installer/compare/v1.6.0...HEAD

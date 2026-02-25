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

## [1.4.0] - 2026-02-24

### Added
- Laravel-optimized PHP drop-in config written to `/etc/php/<version>/fpm/conf.d/99-laravel.ini` on every full install (`memory_limit=256M`, `upload_max_filesize=64M`, `post_max_size=64M`, `max_execution_time=60`, `date.timezone=UTC`, OPcache enabled)
- WordPress installs now also write `/etc/php/<version>/fpm/conf.d/99-wordpress.ini` (`upload_max_filesize=128M`, `post_max_size=128M`, `max_input_vars=3000`)
- `--reconfigure-php [version]` mode — re-applies PHP drop-in settings for an installed PHP version without running the full installer; auto-detects the active version when no argument is given; carries over WordPress settings if present

## [Unreleased]

### Planned Features
- Support for multiple PHP versions
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
[Unreleased]: https://github.com/victoryoalli/lemp-installer/compare/v1.0.0...HEAD

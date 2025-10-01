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
- PHP performance tuning options

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

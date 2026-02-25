# LEMP Installer

Single-file bash installer for a LEMP stack (Nginx, MySQL/PostgreSQL, PHP 8.3, Composer) optimized for Laravel on Ubuntu 24.04.

## Architecture

One file: `install.sh`. All logic lives there — no modules, no subcommands (except `--apply-ssl` and `--reconfigure-php`).

## Key Variables (install.sh)

- `PHP_VERSION` — hardcoded to `"8.3"`
- `SYSTEM_USER` — prompted, defaults to `"web"`; owns `/home/web/www/current/`
- `DOMAIN_NAME` — optional; enables Nginx server_name and SSL flow
- `DB_TYPE` — `"mysql"` or `"postgresql"`
- `PHP_SOCKET` — `/run/php/php${PHP_VERSION}-fpm.sock`

## Modes

- Default: full interactive install
- `--apply-ssl`: writes SSL Nginx config post-certbot; prompts for domain + site name only
- `--reconfigure-php [version]`: writes PHP drop-in config for an installed PHP version; auto-detects if no version given
- `-h` / `--help`: prints usage and exits

## Testing

No automated tests. Test manually on a fresh Ubuntu 24.04 VM:

```bash
sudo bash install.sh           # Full install
sudo bash install.sh --apply-ssl  # SSL config only
```

## Gotchas

- PHP drop-in config written to `/etc/php/<version>/fpm/conf.d/99-laravel.ini` (memory_limit=256M, upload=64M, OPcache enabled, timezone=UTC)
- WordPress installs get an additional `/etc/php/<version>/fpm/conf.d/99-wordpress.ini` (upload=128M, max_input_vars=3000)
- Wildcard SSL uses manual DNS-01 challenge — certbot pauses twice for TXT records; cannot auto-renew
- MySQL password safety: uses a temp `.my.cnf` file instead of CLI flag to avoid `ps aux` leaks
- SSH public key is piped via stdin (not embedded in shell string) to handle keys containing single quotes
- Log file created at mode `600` (root-only) before any sensitive output is written
- `--apply-ssl` detects the PHP-FPM socket automatically via `ls /run/php/php*-fpm.sock`
- `post_max_size` must be ≥ `upload_max_filesize` if either is changed manually post-install

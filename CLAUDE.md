# LEMP Installer

Single-file bash installer for a LEMP stack (Nginx, MySQL/PostgreSQL, PHP 8.3, Composer) optimized for Laravel on Ubuntu 24.04.

## Architecture

One file: `install.sh`. All logic lives there — no modules, no subcommands (except `--apply-ssl`, `--reconfigure-php`, and `--fix-permissions`).

Extended docs live in `docs/` (installation, laravel-deployment, troubleshooting, security, faq) and are linked from the README's Documentation section — keep them in sync with behavior changes in `install.sh`.

## Key Variables (install.sh)

- `PHP_VERSION` — hardcoded to `"8.3"`
- `SYSTEM_USER` — prompted, defaults to `"web"`; owns `/home/web/www/` (`releases/`, `shared/`, `current` symlink)
- `DOMAIN_NAME` — optional; enables Nginx server_name and SSL flow
- `DB_TYPE` — `"mysql"` or `"postgresql"`
- `PHP_SOCKET` — `/run/php/php${PHP_VERSION}-fpm-${SYSTEM_USER}.sock` (per-user pool)

## Modes

- Default: full interactive install
- `--apply-ssl`: writes SSL Nginx config post-certbot; prompts for domain + site name only
- `--reconfigure-php [version]`: writes PHP drop-in config for an installed PHP version; auto-detects if no version given
- `--fix-permissions`: retrofits an existing server — per-user FPM pool, home-dir 750 + group, ownership of `~/www`, repoints Nginx configs to the new socket (with backup/rollback)
- `-h` / `--help`: prints usage and exits

## Testing

No automated tests. Test manually on a fresh Ubuntu 24.04 VM:

```bash
sudo bash install.sh           # Full install
sudo bash install.sh --apply-ssl  # SSL config only
```

Full manual test plan (fresh install, retrofit from 1.4.0, release-flip/OPcache check, sign-off checklist): `docs/testing.md`.

## Gotchas

- PHP drop-in config written to `/etc/php/<version>/fpm/conf.d/99-laravel.ini` (memory_limit=256M, upload=64M, OPcache enabled, timezone=UTC)
- WordPress installs get an additional `/etc/php/<version>/fpm/conf.d/99-wordpress.ini` (upload=128M, max_input_vars=3000)
- Wildcard SSL uses manual DNS-01 challenge — certbot pauses twice for TXT records; cannot auto-renew
- MySQL password safety: uses a temp `.my.cnf` file instead of CLI flag to avoid `ps aux` leaks
- SSH public key is piped via stdin (not embedded in shell string) to handle keys containing single quotes
- Log file created at mode `600` (root-only) before any sensitive output is written
- `--apply-ssl` detects the PHP-FPM socket automatically, preferring `php*-fpm-<user>.sock` (per-user pool) before falling back to `php*-fpm.sock`
- `post_max_size` must be ≥ `upload_max_filesize` if either is changed manually post-install
- PHP-FPM runs as `$SYSTEM_USER` via a dedicated pool (`pool.d/<user>.conf`); the stock `www` pool is disabled (renamed `.disabled`) on fresh installs only — `--fix-permissions` never touches it (other sites may use it)
- Home dir is `750` with `www-data` added to the user's group; nginx needs a **restart** (not reload) to pick up new group membership
- All generated PHP location blocks `include snippets/fastcgi-php-realpath.conf` (written by `write_realpath_snippet()`); it must exist before `nginx -t` passes
- `~/www/current` is a symlink to `~/www/releases/<name>`; `--fix-permissions` must never restructure a flat `current/` directory (live server) — it prints migration guidance instead
- Nginx uses `$realpath_root` for `SCRIPT_FILENAME`/`DOCUMENT_ROOT` so OPcache caches real release paths (no stale code after a symlink flip)

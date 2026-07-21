# Frequently Asked Questions

## Why does PHP-FPM run as `web` instead of `www-data`?

Because the deploy user and the PHP user being different is the root cause of ~90% of Laravel permission problems: `web` writes the files, `www-data` needs to write `storage/` and `bootstrap/cache/`, and the usual "fix" is `chmod 777`. Running the pool as `web` makes writer and owner the same user, so no permission juggling is ever needed. Nginx stays as `www-data` and keeps zero write access to your application. See the [Security Guide](security.md) for the full rationale.

## Why is `current` a symlink?

The releases layout (`~/www/releases/<name>` + `current` symlink) gives you:

- **Near-instant activation** — a deploy becomes live by flipping one symlink, not by copying files over a running app.
- **Rollback** — point `current` back at the previous release.
- **Shared state** — `storage/` and `.env` live in `~/www/shared/` and survive every deploy.

Nginx passes `$realpath_root` to PHP so OPcache caches the *resolved* release path — new code is served immediately after the flip, no PHP-FPM restart.

## I have a server installed with an older version. How do I migrate?

Run:

```bash
sudo ./install.sh --fix-permissions
```

It creates the per-user PHP-FPM pool, fixes home-dir and project permissions, and repoints your Nginx configs to the new socket (with backups and automatic rollback if `nginx -t` fails). It does **not** convert a flat `current/` directory into the releases layout — that involves moving a live application, so the script prints the manual steps instead.

## Can I use a user other than `web`?

Yes. The installer prompts for the system user (default `web`). Everything — the home directory, the FPM pool name, the socket path (`/run/php/php8.3-fpm-<user>.sock`), the group `www-data` joins — follows the name you choose.

## Can I host multiple sites on one server?

The installer provisions one site per run and is optimized for that case. For a second site under a *different* user you can create the user, pool, and Nginx config by hand following the same pattern (or re-run relevant parts manually). Note that on fresh installs the stock `www` pool is disabled; `--fix-permissions` never disables it, precisely because other sites might use it.

## How do I upgrade PHP later?

1. Install the new PHP version and extensions.
2. Re-apply the Laravel settings: `sudo ./install.sh --reconfigure-php 8.4`
3. The per-user pool does not carry over between PHP versions — the script will warn you about this; run `sudo ./install.sh --fix-permissions` to recreate the pool for the new version and repoint Nginx.

## Why does Nginx return 403 when all my project permissions look right?

Almost always `/home/web` traversal: Ubuntu homes are restrictive by default, and Nginx (as `www-data`) can't pass through. The installer sets the home to `750` and adds `www-data` to the `web` group. If you see 403s, check `id www-data` lists `web`, and remember Nginx needs a **restart** (not reload) after group changes. Details in [Troubleshooting](troubleshooting.md#403-forbidden).

## Do I need to run `chmod -R 775 storage` after deploying?

No — that advice is for setups where PHP runs as a different user than the deployer. Here they're the same user, so permissions are automatic. If you find yourself needing `chmod`, something is running as the wrong user (root artisan commands, or a worker not set to `user=web`).

## Why can't wildcard certificates renew automatically?

Wildcard certs use the DNS-01 challenge, which requires creating TXT records in your DNS. The installer uses certbot's *manual* mode, so there's no API hook to automate the record creation. Renew manually every ~90 days and reload Nginx. If your DNS provider has a certbot plugin (Cloudflare, Route53, etc.), you can switch to it for automatic renewal.

## Does the installer work on Ubuntu 22.04?

It's optimized and tested for 24.04. On 22.04 it will warn you and let you continue — the same steps generally work, but package versions differ.

## Where are the logs?

- Installer: `/var/log/lemp-install-YYYYMMDD-HHMMSS.log` (mode `600`, root-only)
- Nginx: `/var/log/nginx/error.log` and `access.log`
- PHP-FPM: `journalctl -u php8.3-fpm`
- Laravel: `~/www/shared/storage/logs/laravel.log`
- Queue workers (Supervisor): `~/www/shared/storage/logs/worker.log`

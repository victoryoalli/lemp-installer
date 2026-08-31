# Troubleshooting

Quick diagnosis table, then details for each symptom.

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| 403 Forbidden with correct project permissions | `www-data` can't traverse `/home/web` | [Home directory access](#403-forbidden) |
| "Permission denied" writing to `storage/logs` | Log file created by another user (root or a worker) | [Storage permissions](#permission-denied-in-storage) |
| Old code served after a deploy | Nginx config missing `$realpath_root` (pre-1.5.0) | [Stale code](#stale-code-after-a-deploy) |
| Config cache won't regenerate | `bootstrap/cache` files owned by root | Never run `artisan` as root; fix with `chown` |
| Jobs process old code | Workers not restarted after deploy | `php artisan queue:restart` |
| 502 Bad Gateway | PHP-FPM down or wrong socket path in Nginx | [502](#502-bad-gateway) |

---

## 502 Bad Gateway

PHP-FPM is not running, or Nginx points at the wrong socket.

```bash
sudo systemctl status php8.3-fpm
ls -la /run/php/
```

On v1.5.0+ you should see the per-user pool socket, owned by `www-data:www-data` with mode `0660`:

```
srw-rw---- 1 www-data www-data 0 ... /run/php/php8.3-fpm-web.sock
```

Check what your Nginx config points at:

```bash
grep fastcgi_pass /etc/nginx/sites-available/*
```

If it still references the old `/run/php/php8.3-fpm.sock`, run `sudo ./install.sh --fix-permissions`. If the socket is missing entirely:

```bash
sudo journalctl -u php8.3-fpm -n 50
sudo systemctl restart php8.3-fpm
```

## 403 Forbidden

Nginx (running as `www-data`) needs to traverse `/home/web` to reach the document root. Ubuntu creates home directories with restrictive modes, so this fails even when the project permissions are perfect — check the Nginx error log and you'll see "permission denied" on `/home/web`.

The installer solves this with the restrictive option: home at `750` plus `www-data` in the `web` group. Verify and repair:

```bash
id www-data                        # must list "web" among the groups
stat -c '%a %U:%G' /home/web       # expect: 750 web:web

sudo usermod -aG web www-data      # if the group is missing
sudo chmod 750 /home/web
sudo systemctl restart nginx       # restart, not reload — workers must pick up the group
```

The quick-but-looser alternative is `chmod 751 /home/web` (any local user can traverse). Prefer the group approach.

You should **never** need `chmod 755 /home/web` or `chmod -R 775` on the project. If those seem necessary, PHP-FPM is probably not running as `web` — run `sudo ./install.sh --fix-permissions`.

## Permission Denied in storage/

On v1.5.0+ this almost always means a file was created by the wrong user:

- You ran `artisan` or `composer` **as root** — the cache/log files are now root-owned and PHP-FPM (running as `web`) can't touch them.
- A **queue worker runs as another user** and wrote `storage/logs/laravel.log` first.

Diagnose and fix:

```bash
ls -la /home/web/www/shared/storage/logs/
ps aux | grep php-fpm          # workers should show user "web"
sudo supervisorctl status      # check the worker's user= in its config

sudo chown -R web:web /home/web/www
```

Then stop running things as root: deploy as `web`, and set `user=web` in the Supervisor program.

## Stale Code After a Deploy

If flipping the `current` symlink doesn't change what's served, OPcache is caching paths through the symlink. v1.5.0 configs prevent this by passing `$realpath_root` to PHP:

```bash
grep -r realpath_root /etc/nginx/
```

Every generated site includes `/etc/nginx/snippets/fastcgi-php-realpath.conf`, which sets:

```nginx
fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
fastcgi_param DOCUMENT_ROOT $realpath_root;
```

If your config predates v1.5.0, run `sudo ./install.sh --fix-permissions` (it swaps the include and creates backups). As a one-off workaround, `sudo systemctl restart php8.3-fpm` clears OPcache.

Also remember: **queue workers keep the old code in memory** — run `php artisan queue:restart` after every deploy.

## Database Connection Errors

Wrong credentials or missing grants:

```bash
mysql -u web -p                       # MySQL
psql -h localhost -U web -d postgres  # PostgreSQL
```

```sql
-- MySQL, as root:
GRANT ALL PRIVILEGES ON my_app.* TO 'web'@'localhost';
FLUSH PRIVILEGES;
```

Check that `.env` (in `~/www/shared/.env`) matches the database name, user, and password you created.

## Site Won't Open in the Browser, but `curl http://...` Works

If the server answers `curl http://yourdomain` with `200` but the browser shows "This site can't be reached", the cause is almost always a missing SSL setup on an **HSTS-preloaded TLD**. Entire TLDs like `.dev`, `.app`, and `.page` are hardcoded into Chrome, Firefox, and Safari as HTTPS-only — the browser never even attempts plain HTTP.

Fix it by adding SSL (certbot is only installed if you answered yes to SSL during install):

```bash
sudo snap install --classic certbot
sudo ln -sf /snap/bin/certbot /usr/bin/certbot
sudo certbot --nginx -d yourdomain.dev
```

`certbot --nginx` edits the site config, adds the certificate, and sets up the HTTP→HTTPS redirect automatically.

## Wildcard SSL Renewal

Wildcard certificates obtained via the manual DNS-01 challenge **cannot renew automatically**. Every ~90 days:

```bash
sudo certbot certonly --manual --preferred-challenges dns \
  -d '*.yourdomain.com' -d 'yourdomain.com'
sudo systemctl reload nginx
```

You do **not** need to run `--apply-ssl` again — only the certificate files change.

## Where to Look

```bash
sudo tail -f /var/log/nginx/error.log        # Nginx errors (403s, socket issues)
sudo journalctl -u php8.3-fpm -f             # PHP-FPM service errors
tail -f /home/web/www/shared/storage/logs/laravel.log   # application errors
ls /var/log/lemp-install-*.log               # installer logs (root-only)
```

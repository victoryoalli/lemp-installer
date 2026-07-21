# Laravel Deployment Guide

How to deploy Laravel applications on a server provisioned by this installer (v1.5.0+).

## The Model

- **PHP-FPM runs as your deploy user** (`web`), not `www-data`. Whatever you deploy, PHP can read and write — `storage/` and `bootstrap/cache/` permission errors simply cannot happen as long as you deploy as `web`.
- **Nginx runs as `www-data`** and only serves static files and forwards PHP requests to the socket.
- **`~/www/current` is a symlink** pointing at the active release. Deploys are activated by flipping it.
- **`~/www/shared/`** holds everything that must survive deploys: `storage/` and `.env`.

Two rules keep this working:

1. **Always deploy and run `artisan`/`composer` as `web`, never as root.** Root-owned cache files break PHP-FPM's ability to regenerate them.
2. **Never `chmod 777` anything.** If something is unreadable, the ownership is wrong — fix the user, not the mode.

## First Deploy

```bash
sudo su - web
cd ~/www/releases
git clone git@github.com:username/repo.git release-1
cd release-1
composer install --no-dev --optimize-autoloader
```

Link the shared resources into the release:

```bash
rm -rf storage && ln -nfs ~/www/shared/storage storage
ln -nfs ~/www/shared/.env .env
```

Configure the environment (it lives in `shared/`, so this is a one-time step):

```bash
cp .env.example ~/www/shared/.env
nano ~/www/shared/.env
```

Run the Laravel setup:

```bash
php artisan key:generate
php artisan storage:link
php artisan migrate --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

Activate the release:

```bash
ln -nfs ~/www/releases/release-1 ~/www/current
php artisan queue:restart   # if you run queue workers
```

The new code is served immediately: Nginx passes `$realpath_root` to PHP, so OPcache caches the resolved release path — no PHP-FPM restart needed.

## Subsequent Deploys

Repeat with a fresh release directory (a timestamp works well):

```bash
sudo su - web
cd ~/www/releases
git clone git@github.com:username/repo.git 2026-07-20-001
cd 2026-07-20-001
composer install --no-dev --optimize-autoloader
rm -rf storage && ln -nfs ~/www/shared/storage storage
ln -nfs ~/www/shared/.env .env
php artisan migrate --force
php artisan config:cache && php artisan route:cache && php artisan view:cache
ln -nfs ~/www/releases/2026-07-20-001 ~/www/current
php artisan queue:restart
```

Delete old releases when you no longer need them for rollback.

> **Note:** `ln -nfs` briefly unlinks before recreating the symlink. If you need a fully atomic flip: `ln -s ~/www/releases/2026-07-20-001 ~/www/current-tmp && mv -T ~/www/current-tmp ~/www/current`.

## Rollback

Point `current` back at the previous release and restart the workers:

```bash
ln -nfs ~/www/releases/release-1 ~/www/current
php artisan queue:restart
```

(If the new release ran migrations, roll those back first or restore the database.)

## Queue Workers with Supervisor

```bash
sudo apt install supervisor
sudo nano /etc/supervisor/conf.d/laravel-worker.conf
```

```ini
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /home/web/www/current/artisan queue:work --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=web
numprocs=2
redirect_stderr=true
stdout_logfile=/home/web/www/shared/storage/logs/worker.log
stopwaitsecs=3600
```

```bash
sudo supervisorctl reread && sudo supervisorctl update
```

**`user=web` matters.** A worker running as another user creates log files the web processes can't write to — the classic intermittent "Permission denied" in `storage/logs`. After every deploy, run `php artisan queue:restart` so workers pick up the new code (they hold the old release's code in memory until restarted).

If two users must ever write the same logs, set an explicit permission on the daily channel in `config/logging.php`:

```php
'daily' => [
    'driver' => 'daily',
    'path' => storage_path('logs/laravel.log'),
    'level' => env('LOG_LEVEL', 'debug'),
    'days' => 14,
    'permission' => 0664,
],
```

## Scheduler

Add the cron entry as `web` (`crontab -e` while logged in as `web`):

```cron
* * * * * cd /home/web/www/current && php artisan schedule:run >> /dev/null 2>&1
```

## Post-Deploy Checklist

- [ ] Release files owned by `web:web`
- [ ] `storage/` and `.env` symlinks point into `shared/`
- [ ] `config:cache`, `route:cache`, `view:cache` run as `web`
- [ ] `current` symlink points at the new release
- [ ] `php artisan queue:restart` executed
- [ ] No 403 or "permission denied" entries in `/var/log/nginx/error.log`

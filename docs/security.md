# Security Guide

What the installer hardens for you, why the permission model is safe, and what to do afterwards.

## Script Hardening

Measures built into `install.sh`:

- **Log file protection** — the install log is created with mode `600` (root-only) *before* any sensitive output is written to it.
- **Input validation** — usernames, site names, and domain names are validated against strict patterns to prevent shell and SQL injection.
- **MySQL password safety** — the connection test uses a temporary `.my.cnf` file instead of a command-line flag, so the password never appears in `ps aux`.
- **PostgreSQL identifier quoting** — the database username is double-quoted in SQL to prevent injection via a crafted username.
- **SSH key safety** — the public key is piped via stdin rather than embedded in a shell string, so keys containing quotes can't inject commands.

## The Permission Model (v1.5.0+)

### Why PHP-FPM runs as the deploy user

The classic conflict: `web` writes files during deploys, but PHP-FPM (as `www-data`) needs to read everything and write `storage/` and `bootstrap/cache/`. People "solve" it with `chmod 777` — which lets *any* local process write your application code.

Instead, the installer gives PHP its own pool running as `web`. PHP and deploys are the same user, so nothing ever needs to be group-writable to a second user, and `777` is never needed. Privilege separation is preserved where it matters:

- **Nginx stays `www-data`** and holds no write access to the application at all — it only reads static files and talks to the socket.
- **The FPM socket** (`/run/php/php8.3-fpm-web.sock`) is owned `www-data:www-data` mode `0660`: only Nginx can connect to PHP, and only PHP-FPM's master (root) creates the socket.
- **Per-site isolation**: each site can get its own user + pool, so one compromised app can't read another's files.

### Why the home directory is 750

`/home/web` at `750` blocks other local users from reading the application (including `.env` reachable through `~/www/shared`). Nginx gets traversal by `www-data` being a member of the `web` group — the minimal grant that works. The alternative (`chmod 751`) lets *every* local user traverse; prefer the group.

Note that `www-data` in the `web` group means Nginx can also read group-readable files under `/home/web`. Keep secrets tight: the installer creates `shared/.env` with mode `640`.

### Rules that keep it safe

1. Never `chmod 777` anything.
2. Never run `artisan`/`composer` as root in production — root-owned caches break the model and widen the blast radius.
3. Queue workers must run as `web` (`user=web` in Supervisor).

## Post-Installation Best Practices

### 1. Change the SSH port

```bash
sudo nano /etc/ssh/sshd_config    # Port 22 -> Port 2222
sudo systemctl restart sshd
```

If UFW is enabled, allow the new port before disconnecting: `sudo ufw allow 2222/tcp`.

### 2. Disable root login and password authentication

```bash
sudo nano /etc/ssh/sshd_config
# PermitRootLogin no
# PasswordAuthentication no   (only after confirming key-based login works!)
sudo systemctl restart sshd
```

### 3. Install Fail2Ban

```bash
sudo apt install fail2ban
sudo systemctl enable --now fail2ban
```

### 4. Keep the system updated

```bash
sudo apt update && sudo apt upgrade -y
```

Consider `unattended-upgrades` for automatic security patches:

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### 5. Replace the phpinfo placeholder

The initial release serves a `phpinfo()` page, which reveals PHP configuration details. Replace it with your application (or a static page) as soon as the server is reachable from the internet.

### 6. Protect the database

- Use a dedicated database user per application with grants only on that app's database.
- Don't expose MySQL/PostgreSQL ports publicly; the installer leaves them bound locally, and UFW (if enabled) only opens SSH and HTTP/HTTPS.

### 7. Laravel production settings

In `~/www/shared/.env`:

```env
APP_ENV=production
APP_DEBUG=false
```

`APP_DEBUG=true` in production leaks environment variables and secrets on any error page.

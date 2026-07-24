# Manual Test Plan — v1.5.0 Permission Changes

How to validate the v1.5.0 changes (per-user PHP-FPM pool, releases/shared layout, `$realpath_root`, `--fix-permissions`) on real servers **before merging to `main`**.

There are no automated tests in this project; this is the release gate.

## Environments Needed

Two fresh Ubuntu 24.04 machines (VMs, droplets, or Multipass instances):

| VM | Purpose |
|----|---------|
| `lemp-fresh` | Fresh install of the branch version (tests T1–T4, T6, T7) |
| `lemp-retrofit` | v1.4.0 baseline install, then `--fix-permissions` (tests T5, T7) |

With Multipass:

```bash
multipass launch 24.04 --name lemp-fresh --memory 2G --disk 10G
multipass launch 24.04 --name lemp-retrofit --memory 2G --disk 10G
multipass shell lemp-fresh
```

On a cloud provider, take a snapshot right after the VM boots so you can re-run tests from a clean state.

## Getting the Scripts

The branch version (the code under test):

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/heads/feat/permission-improvement/install.sh -o install.sh
```

The v1.4.0 baseline (only for the retrofit VM):

```bash
curl -fsSL https://raw.githubusercontent.com/victoryoalli/lemp-installer/refs/tags/v1.4.0/install.sh -o install-1.4.0.sh
```

---

## T1 — Fresh Install

On `lemp-fresh`:

```bash
sudo bash install.sh
```

Suggested answers: MySQL, db user `web` + any password, system user `web`, site name `testsite`, **no** domain, **no** WordPress, **no** SSL, **no** SSH key paste, **no** firewall.

The install must finish with "Installation Completed Successfully" and the summary must show:

- `Web root: /home/web/www/current/public (current -> releases/initial)`
- `PHP-FPM pool: web (runs as web)`
- `PHP socket: /run/php/php8.3-fpm-web.sock`

### Automated verification

Paste this as root (`sudo -i`) after the install:

```bash
cat > /root/verify-lemp.sh << 'EOF'
#!/bin/bash
# Verifies the v1.5.0 permission model on a fresh install
user=web
ver=8.3
sock="/run/php/php${ver}-fpm-${user}.sock"
fail=0
ok()  { echo "PASS: $1"; }
bad() { echo "FAIL: $1"; fail=1; }

[ -S "$sock" ] && ok "per-user socket exists" || bad "per-user socket exists ($sock)"
[ "$(stat -c '%U:%G %a' "$sock" 2>/dev/null)" = "www-data:www-data 660" ] \
    && ok "socket owned www-data:www-data mode 660" || bad "socket owner/mode"
[ -f "/etc/php/${ver}/fpm/pool.d/${user}.conf" ] && ok "pool file exists" || bad "pool file exists"
[ ! -f "/etc/php/${ver}/fpm/pool.d/www.conf" ] && ok "stock www pool disabled" || bad "stock www pool disabled"
ps -eo user:20,comm | grep php-fpm | grep -qw "$user" \
    && ok "FPM workers run as $user" || bad "FPM workers run as $user"
[ "$(stat -c '%a' "/home/$user")" = "750" ] && ok "home dir is 750" || bad "home dir is 750"
id -nG www-data | grep -qw "$user" && ok "www-data is in group $user" || bad "www-data in group $user"
sudo -u www-data test -x "/home/$user" && ok "www-data can traverse home" || bad "www-data traversal"
[ -L "/home/$user/www/current" ] && ok "current is a symlink" || bad "current is a symlink"
[ -d "/home/$user/www/shared/storage/logs" ] && ok "shared/storage tree exists" || bad "shared/storage tree"
[ -f "/home/$user/www/shared/.env" ] && ok "shared/.env exists" || bad "shared/.env exists"
[ -f /etc/nginx/snippets/fastcgi-php-realpath.conf ] && ok "realpath snippet exists" || bad "realpath snippet"
grep -rq "fastcgi-php-realpath.conf" /etc/nginx/sites-enabled/ \
    && ok "site config uses realpath snippet" || bad "site uses realpath snippet"
grep -rq "unix:$sock" /etc/nginx/sites-enabled/ \
    && ok "site config uses per-user socket" || bad "site uses per-user socket"
curl -s http://localhost/ | grep -q "releases/initial" \
    && ok "phpinfo shows resolved release path (realpath works)" || bad "phpinfo realpath check"

[ $fail -eq 0 ] && echo "== ALL CHECKS PASSED ==" || echo "== FAILURES ABOVE =="
exit $fail
EOF
bash /root/verify-lemp.sh
```

All lines must say `PASS`. Also check manually in the phpinfo page (`curl -s http://localhost/ | grep -A2 '>USER'`) that PHP's `USER` is `web`.

---

## T2 — Real Laravel Deploy

Still on `lemp-fresh`, follow the printed post-install instructions exactly (as `web`, never root): clone a real Laravel app into `~/www/releases/release-1`, `composer install`, link `storage` and `.env` from `shared/`, configure the database, run `artisan` setup, flip `current`.

Must-pass criteria:

- The app loads in the browser / `curl`.
- `php artisan migrate --force` works.
- The app writes logs to `~/www/shared/storage/logs/laravel.log` **without any chmod/chown at any point**.
- `ls -la ~/www/releases/release-1` shows everything owned by `web:web`.

If the VM has no PHP/composer requirements for your app, a fresh `laravel new` skeleton (installed via composer on the VM) is enough.

---

## T3 — Release Flip (the `$realpath_root`/OPcache test)

This is the core regression the new Nginx snippet prevents: old code served after a symlink flip.

```bash
sudo su - web -c 'cp -r ~/www/releases/initial ~/www/releases/flip-test'
sudo su - web -c 'echo "<?php echo \"RELEASE-2\";" > ~/www/releases/flip-test/public/index.php'

curl -s http://localhost/ | grep -o "releases/initial" | head -1   # old release serving

sudo su - web -c 'ln -nfs ~/www/releases/flip-test ~/www/current'
curl -s http://localhost/                                          # must print RELEASE-2
```

**Must pass:** `RELEASE-2` appears **immediately** after the flip — no `systemctl restart php8.3-fpm`, no waiting for `opcache.revalidate_freq`. Flip back afterwards:

```bash
sudo su - web -c 'ln -nfs ~/www/releases/initial ~/www/current'
```

---

## T4 — `--apply-ssl` Socket Detection

Full test requires a real domain + certificate. Without one, use a self-signed dry run:

```bash
sudo mkdir -p /etc/letsencrypt/live/test.local
sudo openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
  -keyout /etc/letsencrypt/live/test.local/privkey.pem \
  -out /etc/letsencrypt/live/test.local/fullchain.pem \
  -subj "/CN=test.local"

sudo bash install.sh --apply-ssl
# domain: test.local — site name: testssl — user: web
```

Must-pass criteria:

- It prints `Detected PHP socket: /run/php/php8.3-fpm-web.sock` (the per-user socket, **not** the stock one).
- `nginx -t` passes and Nginx reloads.
- `curl -ks https://localhost/ -H "Host: test.local"` serves the site over TLS.

Cleanup:

```bash
sudo rm /etc/nginx/sites-enabled/testssl /etc/nginx/sites-available/testssl
sudo rm -rf /etc/letsencrypt/live/test.local
sudo systemctl reload nginx
```

---

## T5 — Retrofit an Existing Server (`--fix-permissions`)

On `lemp-retrofit`, first build the old-world baseline:

```bash
sudo bash install-1.4.0.sh
# same answers as T1
```

Confirm the baseline is the old model: `ps -eo user:20,comm | grep php-fpm` shows `www-data` workers, `/run/php/php8.3-fpm.sock` exists, `~web/www/current` is a **plain directory**, `stat -c '%a' /home/web` is `755`.

While still on the baseline, check the upgrade warning (part of T7):

```bash
sudo bash install.sh --reconfigure-php
# expect: "No per-user PHP-FPM pool found for PHP 8.3" + suggestion to run --fix-permissions
```

Now run the retrofit:

```bash
sudo bash install.sh --fix-permissions
# user: web
```

Must-pass criteria:

- `/etc/php/8.3/fpm/pool.d/web.conf` created; `www.conf` **still present and untouched** (both sockets now exist in `/run/php/`).
- `ps` shows `php-fpm` workers running as `web`.
- `stat -c '%a' /home/web` is `750`; `id -nG www-data` includes `web`.
- The site config in `sites-available` now has `fastcgi_pass unix:/run/php/php8.3-fpm-web.sock;` and `include snippets/fastcgi-php-realpath.conf;`, and a `.bak.<timestamp>` backup of the original exists next to it.
- The site still serves: `curl -s http://localhost/` works.
- The script printed the warning about `www/current` being a plain directory, with manual migration steps — and did **not** restructure it.
- Everything under `~/www` is owned `web:web`.

### Idempotency

Run it a second time:

```bash
sudo bash install.sh --fix-permissions
```

Must-pass: it completes cleanly, and the site config content is unchanged (`diff` the config against the backup created by the *second* run — they must be identical). The site still serves.

---

## T6 — WordPress Path (optional but recommended)

On a reset `lemp-fresh` (or a third VM), run the fresh install answering **yes** to WordPress, then install WordPress into a release. Must-pass: permalinks work (the new snippet preserves `PATH_INFO` handling), uploads work, and `/etc/php/8.3/fpm/conf.d/99-wordpress.ini` exists.

---

## T7 — Mode Smoke Tests

```bash
sudo bash install.sh -h                 # usage lists --fix-permissions with example
sudo bash install.sh --reconfigure-php  # on lemp-fresh: NO per-user-pool warning
                                        # (pool exists); on the 1.4.0 baseline: warning shown (see T5)
```

---

## Sign-off Checklist (before merging to main)

- [ ] T1: all verification script checks PASS on a fresh install
- [ ] T2: real Laravel app deployed with zero manual permission commands
- [ ] T3: release flip serves new code immediately (no FPM restart)
- [ ] T4: `--apply-ssl` detects the per-user socket and the TLS site serves
- [ ] T5: `--fix-permissions` retrofits a 1.4.0 server, leaves `www.conf` alone, creates backups, and is idempotent
- [ ] T6 (optional): WordPress permalinks and uploads work
- [ ] T7: help text and `--reconfigure-php` warning behave as expected

If any test fails, fix on the branch, push, re-download the raw script on the VM, and re-run the affected test from a clean snapshot when the failure could have left state behind.

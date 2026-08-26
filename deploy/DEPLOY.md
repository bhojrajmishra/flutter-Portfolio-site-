# Deploying to your VPS + custom domain

This walks through putting the site live on your own domain, on a **VPS
you fully control** (root/sudo, your own Nginx/PM2). Do this once for
initial setup; after that, `./deploy/deploy.sh` handles routine updates.

**On shared/PaaS hosting instead (e.g. alwaysdata), see
[`ALWAYSDATA.md`](ALWAYSDATA.md)** — same app and database, but sites,
databases, domains and SSL are provisioned through a web admin panel
rather than files you edit yourself.

## 0. What you'll need

- SSH access to your VPS (IP address + a user with sudo)
- Your domain's DNS management (registrar or wherever DNS is hosted)
- The VPS reachable on ports 80 and 443 (open in any cloud firewall/security group)

## 1. Point your domain at the VPS

In your domain's DNS settings, add:

| Type | Name | Value          |
|------|------|----------------|
| A    | @    | `<VPS IP>`     |
| A    | www  | `<VPS IP>`     |

DNS propagation can take a few minutes to a few hours. Check with:
```bash
dig +short yourdomain.com
```

## 2. Install prerequisites on the VPS

SSH in, then:

```bash
# Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# MySQL
sudo apt-get install -y mysql-server
sudo mysql_secure_installation

# Nginx, PM2, Certbot
sudo apt-get install -y nginx
sudo npm install -g pm2
sudo apt-get install -y certbot python3-certbot-nginx
```

Create the database and an app-scoped user (replace the password):

```sql
sudo mysql
CREATE DATABASE portfolio;
CREATE USER 'portfolio'@'localhost' IDENTIFIED BY 'a-strong-password';
GRANT ALL PRIVILEGES ON portfolio.* TO 'portfolio'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

## 3. Lay out the app directory

```bash
sudo mkdir -p /var/www/portfolio/frontend /var/www/portfolio/backend
sudo chown -R $USER:$USER /var/www/portfolio
```

## 4. Apply the database schema

```bash
mysql -u portfolio -p portfolio < backend/sql/schema.sql
```

## 5. Configure the backend

Copy `backend/.env.example` to `/var/www/portfolio/backend/.env` on the server
and fill in real values:

```
DATABASE_URL="mysql://portfolio:a-strong-password@localhost:3306/portfolio"
PORT=3000
JWT_SECRET="<openssl rand -hex 32>"
JWT_EXPIRES_IN="12h"
ADMIN_EMAIL="you@yourdomain.com"
ADMIN_PASSWORD="<a strong password you'll change after first login is available>"
CORS_ORIGINS="https://yourdomain.com,https://www.yourdomain.com"
PUBLIC_BASE_URL="https://yourdomain.com"
```

## 6. Nginx site

```bash
sudo cp deploy/nginx.conf /etc/nginx/sites-available/portfolio
sudo sed -i 's/yourdomain.com/YOUR_ACTUAL_DOMAIN/g' /etc/nginx/sites-available/portfolio
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 7. First deploy

From your local machine, edit `deploy/deploy.sh` — set `VPS_USER`, `VPS_HOST`,
`VPS_APP_DIR` — then run it:

```bash
./deploy/deploy.sh
```

This builds the Flutter web release, syncs both frontend and backend to the
server, installs backend deps, and starts the API under PM2 (first run) or
reloads it (subsequent runs).

On the server, seed the admin user and placeholder content once. Use the
compiled script directly (`npm run seed` invokes `ts-node`, a devDependency
not installed by `npm ci --omit=dev`):

```bash
ssh youruser@your.server.ip
cd /var/www/portfolio/backend
node dist/src/scripts/seed.js
pm2 save        # persist the process list across reboots
pm2 startup      # follow the printed instructions to enable PM2 on boot
```

## 8. HTTPS

```bash
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

Certbot edits `/etc/nginx/sites-available/portfolio` in place to add the TLS
server block and redirect HTTP -> HTTPS, and sets up auto-renewal.

## 9. Verify

- `https://yourdomain.com` loads the public site with a valid padlock.
- `https://yourdomain.com/admin/login` — sign in with `ADMIN_EMAIL` /
  `ADMIN_PASSWORD` from `.env`, then **change the password by re-seeding
  with a new `ADMIN_PASSWORD` and re-running `node dist/src/scripts/seed.js`**
  (upserts the existing admin's password hash).
- Edit some content in the admin panel and confirm it appears on the public
  page.
- Submit the public contact form and confirm the message shows up in
  Admin -> Messages.

## Routine updates

After the first deploy, ship changes with:

```bash
./deploy/deploy.sh
```

It rebuilds the Flutter web release, re-syncs both frontend and backend,
and reloads the API — your data (MySQL, uploaded files) is untouched. If a
change added new tables/columns, apply the updated `sql/schema.sql`
manually first (it uses `CREATE TABLE IF NOT EXISTS`, so it's safe to
re-run against an existing database).

# How this portfolio was built and deployed — a beginner's walkthrough

This is the full command-by-command record of how the Flutter + Node/MySQL
portfolio at **https://bhojrajmishra.com.np** was built, deployed to
alwaysdata, and later updated. Written so you can follow along, learn the
flow, and repeat any of it yourself.

---

## 1. The big picture

- **`frontend/`** — a Flutter app, compiled into plain HTML/CSS/JS via
  `flutter build web`. The output is *static files* — no server needed to
  run it, just something to host the files.
- **`backend/`** — a Node.js/Express API. This *does* need a server process
  running continuously (it talks to the MySQL database, handles login,
  etc).
- **MySQL database** — hosted by alwaysdata separately from your files.
- **alwaysdata** — shared web hosting. You get an account with a home
  directory (`/home/bhojrajmishra/`), SSH access to it, and a web control
  panel (`admin.alwaysdata.com`) where you tell alwaysdata "serve this
  folder as static files" or "run this folder as a Node.js app."

The split matters: **SSH commands** move your code onto the server.
**The admin panel** tells alwaysdata what to *do* with that code (which
folder is a website, which folder is a running app, which domain points
where, SSL on/off). Neither one can do the other's job.

```
Your Flutter code (frontend/)  ──┐
Your Node.js code (backend/)   ──┼──► built locally on this machine
                                  │
                                  ▼
                    tar + scp over SSH to alwaysdata
                                  │
                                  ▼
        /home/bhojrajmishra/portfolio/{frontend,backend}
                                  │
        ┌─────────────────────────┴─────────────────────────┐
        ▼                                                     ▼
  "Static files" Site                              "Node.js" Site
  serves frontend/ at  /                            runs backend/dist/src/server.js at /api
        │                                                     │
        └───────────────┬─────────────────────────────────────┘
                         ▼
              https://bhojrajmishra.com.np
                         │
                         ▼
              MySQL on mysql-bhojrajmishra.alwaysdata.net
```

---

## 2. One-time setup (done once, first deployment)

### 2.1 Generate a dedicated SSH key (instead of typing a password every time)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/alwaysdata_portfolio -N "" -C "portfolio-deploy"
```

This creates two files: `alwaysdata_portfolio` (private key — never share
this) and `alwaysdata_portfolio.pub` (public key — safe to share, this is
what gets installed on the server).

### 2.2 Install the public key on the server

The very first connection has to use the password, once, to place the key:

```bash
ssh bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && \
   echo 'ssh-ed25519 AAAA... portfolio-deploy' >> ~/.ssh/authorized_keys && \
   chmod 600 ~/.ssh/authorized_keys"
```

(paste the actual contents of `alwaysdata_portfolio.pub` in place of the
`ssh-ed25519 AAAA...` bit)

From then on, every command uses the key instead of the password:

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net "whoami"
```

`-o IdentitiesOnly=yes` tells SSH "only try this specific key" — without
it, SSH sometimes tries other keys on your machine first and can lock you
out temporarily with "too many authentication failures."

### 2.3 Create a separate folder for this project

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "mkdir -p /home/bhojrajmishra/portfolio/frontend /home/bhojrajmishra/portfolio/backend/uploads"
```

Kept fully separate from your other projects (`CMS`, `www/moodle`,
`www/note`) on the same account.

### 2.4 Create the database (done in the admin panel, not SSH)

**admin.alwaysdata.com → Databases → MySQL → Add a database.** This gives
you a database name, username, and password. Test the connection works:

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "mysql -h mysql-bhojrajmishra.alwaysdata.net -u bhojrajmishra_portfolio -p'<password>' bhojrajmishra_portfolio -e 'SELECT 1;'"
```

### 2.5 Build the backend and upload it

```bash
# Locally: compile TypeScript -> plain JavaScript
cd backend
npm run build          # produces backend/dist/

# Package everything the server needs (not node_modules — installed remotely instead)
tar --exclude='node_modules' --exclude='.env' --exclude='uploads' -czf backend.tar.gz .

# Upload
scp -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes backend.tar.gz \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net:/home/bhojrajmishra/portfolio/backend.tar.gz

# Unpack it on the server
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "cd /home/bhojrajmishra/portfolio/backend && tar xzf ../backend.tar.gz && rm ../backend.tar.gz"
```

### 2.6 Create the production `.env` file (secrets — never goes in git)

Written locally, then uploaded directly (not through git, since it holds
passwords):

```bash
scp -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes prod.env \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net:/home/bhojrajmishra/portfolio/backend/.env
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "chmod 600 /home/bhojrajmishra/portfolio/backend/.env"
```

### 2.7 Install backend dependencies *on the server*

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "cd /home/bhojrajmishra/portfolio/backend && npm ci --omit=dev"
```

`--omit=dev` skips developer-only tools (TypeScript compiler, test
runners) — the server only needs what's required to *run* the already-
compiled code, which keeps the file count down (this account has a small
file-count quota).

### 2.8 Apply the database schema and seed starter data

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "cd /home/bhojrajmishra/portfolio/backend && \
   mysql -h mysql-bhojrajmishra.alwaysdata.net -u bhojrajmishra_portfolio -p'<password>' bhojrajmishra_portfolio < sql/schema.sql && \
   node dist/src/scripts/seed.js"
```

`schema.sql` creates all the tables. `seed.js` creates your one admin
login and some starter placeholder content.

### 2.9 Build the frontend and upload it

```bash
cd frontend
flutter build web --release     # produces frontend/build/web/

# Shrink it: Flutter ships several alternate rendering engines "just in
# case" — we only need one, so delete the rest (~25MB saved)
cd build/web/canvaskit
rm -f skwasm*.wasm skwasm*.js skwasm*.js.symbols wimp.wasm wimp.js wimp.js.symbols \
      canvaskit.js.symbols chromium/canvaskit.js.symbols
rm -rf experimental_webparagraph
cd ../../..

tar -C frontend/build/web -czf frontend.tar.gz .
scp -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes frontend.tar.gz \
  bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net:/home/bhojrajmishra/portfolio/frontend.tar.gz
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "cd /home/bhojrajmishra/portfolio/frontend && tar xzf ../frontend.tar.gz && rm ../frontend.tar.gz"
```

### 2.10 Tell alwaysdata what to do with the uploaded files (admin panel)

This is the part that genuinely can't be done via SSH — it's clicking
through the web UI:

1. **Web → Sites → Add a site** — Type `Node.js`, Command
   `node /home/bhojrajmishra/portfolio/backend/dist/src/server.js`,
   Working directory `portfolio/backend`, Address
   `bhojrajmishra.com.np/api`.
2. **Web → Sites → Add a site** — Type `Static files`, directory
   `/home/bhojrajmishra/portfolio/frontend`, Address `bhojrajmishra.com.np`
   (bare, no path — this is the main site).
3. **Web → Sites → Add a site** — Type `Static files`, directory
   `/home/bhojrajmishra/portfolio/backend/uploads`, Address
   `bhojrajmishra.com.np/uploads` (serves uploaded images/resume).
4. **Domains** → attach `bhojrajmishra.com.np` if not already there.
5. On the domain's settings → enable **Let's Encrypt** (free SSL,
   auto-renewing).

---

## 3. Updating the site after that (the repeatable part)

Once the Sites exist, shipping a change is one script:

```bash
./deploy/alwaysdata_deploy.sh
```

What it does, in order (this is literally what section 2.5–2.9 above
does, just scripted):
1. `npm run build` (backend TypeScript → JavaScript)
2. Package + upload `dist/` and `sql/` over SSH
3. Upload `package.json`/`package-lock.json`, run `npm ci --omit=dev`
   remotely (only if dependencies changed — harmless to run every time)
4. `flutter build web --release` (frontend)
5. Strip the unused CanvasKit files (keeps well under the disk quota)
6. Package + upload the frontend build over SSH

**One thing the script can't do:** if you changed backend *code*, the
running Node process doesn't notice until it's restarted. alwaysdata does
not auto-restart on file changes (tested this directly — it really
doesn't). So after any backend change:

> **admin.alwaysdata.com → Web → Sites → the `/api` Node.js site → Restart**

The frontend needs no restart — static files take effect the instant
they're uploaded.

If you added a new database table or column, apply that once by hand
first (the script doesn't touch the database):

```bash
ssh -i ~/.ssh/alwaysdata_portfolio -o IdentitiesOnly=yes bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net \
  "mysql -h mysql-bhojrajmishra.alwaysdata.net -u bhojrajmishra_portfolio -p'<password>' bhojrajmishra_portfolio" \
  < backend/sql/schema.sql
```

---

## 4. Local development (before you even deploy anything)

This is how you'd add a new feature and try it on your own computer first,
without touching the live site at all:

```bash
# 1. Start a local MySQL database in Docker (mirrors production)
docker compose -f deploy/docker-compose.yml up -d

# 2. Run the backend
cd backend
npm install
npm run dev              # http://localhost:3000, auto-restarts on save

# 3. Run the frontend (separate terminal)
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Now you have a real browser window showing the site, talking to a local
database — edit code, save, see it update, with zero risk to the live
site. Only run `./deploy/alwaysdata_deploy.sh` once you're happy with it
locally.

---

## 5. Quick reference — files that matter

| File | What it's for |
|---|---|
| `deploy/alwaysdata_deploy.sh` | The one command to redeploy both apps |
| `deploy/ALWAYSDATA.md` | Full deployment reference for this account |
| `backend/sql/schema.sql` | The database structure (tables/columns) |
| `backend/.env.example` | Template for the server's config — real one lives only on the server, never in git |
| `README.md` | Local dev quickstart |

---

## 6. Summary of what actually happened this session

1. Built the whole app (Flutter frontend + Node/MySQL backend + admin
   panel) from scratch, verified locally.
2. You gave alwaysdata SSH credentials. Discovered it's shared hosting
   (not a VPS) with real constraints: small file-count and disk-space
   quotas, no auto-restart, existing unrelated projects on the account.
3. Rewrote the database layer from Prisma to plain `mysql2` because
   Prisma's tooling didn't fit the file-count quota.
4. Hit the disk quota mid-upload; you chose to delete old unused projects
   (`CMS`, `www/moodle`, `www/note`) to free space — confirmed explicitly
   before doing anything irreversible.
5. Got the site live, verified everything end-to-end on the real domain.
6. You asked for the visual redesign (macOS-style interactive desktop) —
   built it, redeployed, verified again.
7. You asked to match the reference's icons/wallpaper more closely —
   swapped in real brand icons, a live calendar tile, a richer wallpaper,
   admin-editable badges (never fabricated numbers), redeployed, verified
   again.
8. Wrote the reusable deploy script and this walkthrough so the whole
   redeploy flow is one command going forward.

# Deploying to alwaysdata (shared hosting)

This is the guide for **this project's actual deployment target**: the
alwaysdata account `bhojrajmishra`, domain `bhojrajmishra.com.np`.

alwaysdata is shared PaaS hosting, not a VPS — there's no root/sudo, no
`apt-get`, no editing Nginx config files directly, and no Certbot CLI.
Instead: **Sites** (static file hosting or a supervised Node.js process),
**databases**, **domains**, and **SSL certificates** are all provisioned
through the web admin panel at **admin.alwaysdata.com**. SSH is used only to
upload code and run one-off commands (installing deps, applying the schema,
seeding).

## Already done (via SSH, from this machine)

- Confirmed **not** to touch the account's existing `CMS`, `www/moodle`, and
  `www/note` projects — later, those three were explicitly deleted by the
  account owner to free disk quota (see below).
- Backend rewritten from Prisma to plain `mysql2` + raw SQL
  (`backend/sql/schema.sql`) — the account's shared-hosting quota (both a
  file-count/inode limit and a small disk-space limit) couldn't accommodate
  Prisma's client-generation step (engine binaries + generated code). The
  REST API contract is unchanged, so the Flutter frontend needed no changes.
- A dedicated SSH keypair was generated (`~/.ssh/alwaysdata_portfolio` on
  this machine) and installed for passwordless access, replacing the
  password shared in chat.
  **Recommendation: rotate that password** in the alwaysdata admin panel
  (Account > Security) since it was sent in plaintext — the SSH key doesn't
  need it any more, but other services on the account still might.
- Created `/home/bhojrajmishra/portfolio/{frontend,backend}`, fully separate
  from the account's other projects.
- MySQL database `bhojrajmishra_portfolio` confirmed reachable at
  `mysql-bhojrajmishra.alwaysdata.net:3306`; schema applied from
  `backend/sql/schema.sql`; seeded with the admin user and placeholder
  content (`backend/src/scripts/seed.ts`, run compiled as
  `node dist/src/scripts/seed.js` — production installs skip devDependencies
  like `ts-node`).
- Backend built (`npm run build`) and uploaded with only production
  dependencies (`npm ci --omit=dev`, 118 packages, ~16MB) — confirmed
  starting cleanly and serving real data from the production database.
- Frontend built (`flutter build web --release`, default `API_BASE_URL=/api`
  for same-origin requests) and uploaded, **with unused CanvasKit renderer
  variants and debug symbol maps stripped** (skwasm/wimp/experimental
  variants + `*.js.symbols`, ~25MB removed) — the account's total disk quota
  is very small (~200MB) and was fully exhausted by the account's other
  projects plus the unstripped build. The account owner freed space by
  deleting `CMS`, `www/moodle`, and `www/note` entirely (confirmed
  explicitly, itemized, before doing it — irreversible).
- `backend/.env` uploaded directly (not via git) with production secrets —
  see "Credentials" below.

**Current state:** both apps are fully uploaded, tested working (backend
confirmed serving live data from the production database), but **not yet
reachable from the internet** — that requires the manual admin-panel steps
below, which only the account owner can do.

## Remaining steps (admin panel — admin.alwaysdata.com)

### 1. Create the Node.js Site (the API)

**Web > Sites > Add a site**
- Type: **Node.js**
- Command: `node /home/bhojrajmishra/portfolio/backend/dist/src/server.js`
- Working directory: `/home/bhojrajmishra/portfolio/backend`
- Domain: `bhojrajmishra.com.np`
- Path: `/api`
- The app reads `IP`/`PORT` alwaysdata injects automatically (already
  handled in code — see `backend/src/lib/env.ts` / `server.ts`); nothing to
  configure there.

### 2. Create the Static Site (the Flutter build)

**Web > Sites > Add a site**
- Type: **Static files**
- Path/directory: `/home/bhojrajmishra/portfolio/frontend`
- Domain: `bhojrajmishra.com.np`
- Path: `/` (root — must not conflict with the `/api` site above)

### 3. Serve uploaded files (`/uploads`)

**Web > Sites > Add a site**
- Type: **Static files**
- Path/directory: `/home/bhojrajmishra/portfolio/backend/uploads`
- Domain: `bhojrajmishra.com.np`
- Path: `/uploads`

### 4. Attach the domain

If `bhojrajmishra.com.np` isn't already an alwaysdata-managed domain:
**Domains > Add a domain** → enter `bhojrajmishra.com.np` → choose to
manage it. If keeping DNS elsewhere, alwaysdata will show either the
nameservers to delegate to, or a specific record to add at your current DNS
provider — follow what the panel shows after adding the domain.

### 5. Enable SSL

Once the domain resolves to alwaysdata: on the domain (or each Site)'s
settings, enable **Let's Encrypt** — one toggle, auto-renewing.

### 6. Verify

- `https://bhojrajmishra.com.np` loads the public site.
- `https://bhojrajmishra.com.np/admin/login` — sign in (see Credentials).
- Edit content in the admin panel, confirm it appears on the public page.
- Submit the contact form, confirm it shows up in Admin -> Messages.

## Credentials (production)

- **Admin login:** `suman2020j@gmail.com` / the generated password shared
  earlier in this conversation. **Change it** after first login by editing
  `ADMIN_PASSWORD` in `/home/bhojrajmishra/portfolio/backend/.env` on the
  server and re-running `node dist/src/scripts/seed.js` (upserts the
  existing admin's password hash; doesn't touch other content).
- **Database:** `bhojrajmishra_portfolio` / user `bhojrajmishra_portfolio` —
  password as set when the database was created in the admin panel.
- **SSH:** key-based, `~/.ssh/alwaysdata_portfolio` on this machine. Rotate
  the account password since it was shared in plaintext chat.

## Routine updates

There's no `deploy.sh` for this target yet (the generic one assumes
PM2/systemd, which alwaysdata doesn't use — it supervises the Node process
itself once the Site exists). To ship a change:

```bash
# Backend
cd backend && npm run build
scp -i ~/.ssh/alwaysdata_portfolio -r dist bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net:/home/bhojrajmishra/portfolio/backend/
# alwaysdata restarts the Node site automatically on file changes; if not,
# use the "Restart" button on the Site in the admin panel.

# Frontend
cd frontend && flutter build web --release
# strip unused CanvasKit variants + symbol maps before uploading (see
# "Already done" above for the exact file list) — keeps well within quota
scp -i ~/.ssh/alwaysdata_portfolio -r build/web/* bhojrajmishra@ssh-bhojrajmishra.alwaysdata.net:/home/bhojrajmishra/portfolio/frontend/
```

If a change adds new tables/columns, apply the updated `sql/schema.sql`
manually first (`CREATE TABLE IF NOT EXISTS`, safe to re-run).

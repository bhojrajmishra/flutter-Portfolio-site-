# Portfolio (Flutter Web + Admin Panel)

A single-page portfolio (Hero, About/Skills, Projects, Experience/Education,
Resume, Contact) built in Flutter Web, backed by a Node/Express + MySQL API,
with an authenticated admin panel (same Flutter app, at `/admin`) for
managing all the content — no redeploys needed to update your projects,
bio, skills, resume, etc.

```
frontend/   Flutter Web app — public site + admin panel
backend/    Node.js + TypeScript + Express + mysql2 (raw SQL) API
deploy/     Nginx config, PM2 config, deploy script, DEPLOY.md, ALWAYSDATA.md
```

**Live deployment:** https://bhojrajmishra.com.np (alwaysdata shared
hosting) — see [`deploy/ALWAYSDATA.md`](deploy/ALWAYSDATA.md) for what was
done and what's left (a few admin-panel-only steps: creating the Sites,
attaching the domain, enabling SSL).

## Local development

### 1. Database

Start a local MySQL matching production, via Docker:

```bash
docker compose -f deploy/docker-compose.yml up -d
```

(Mapped to host port **3307**, not 3306, in case you already have a native
MySQL install — adjust `deploy/docker-compose.yml` and `backend/.env` if you
don't need that.)

### 2. Backend

```bash
cd backend
cp .env.example .env   # fill in DATABASE_URL (see above), JWT_SECRET, ADMIN_EMAIL/PASSWORD
npm install
mysql -h 127.0.0.1 -P 3307 -u portfolio -pportfolio portfolio < sql/schema.sql
npm run seed             # creates the admin user + placeholder content
npm run dev               # http://localhost:3000
```

### 3. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Visit the public site at `/`, and the admin panel at `/#/admin/login` (sign
in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `backend/.env`).

## Deploying to your domain

- **Shared/PaaS hosting (alwaysdata, this project's actual target):**
  [`deploy/ALWAYSDATA.md`](deploy/ALWAYSDATA.md).
- **A VPS you fully control (root/sudo):**
  [`deploy/DEPLOY.md`](deploy/DEPLOY.md) — DNS, VPS setup
  (Node/MySQL/Nginx/PM2/Certbot), first deploy, HTTPS. `deploy/deploy.sh`
  handles routine updates after that.

## Tech notes

- **Frontend:** Flutter Web, `go_router`, Riverpod, `dio`. Content is fetched
  live from the API on every page load — editing content in the admin panel
  is reflected on the public site immediately, no rebuild required.
- **Backend:** Express + `mysql2` (plain connection pool, raw parameterized
  SQL — see `backend/sql/schema.sql`), JWT-authenticated admin routes,
  `multer` file uploads (images, resume PDF) written to `backend/uploads/`.
  No ORM/codegen step by design — this keeps the footprint small enough for
  file-count/disk-quota-constrained shared hosting.
- **Single admin account:** seeded via `npm run seed` (local) or
  `node dist/src/scripts/seed.js` (production, no devDependencies) from
  `ADMIN_EMAIL` / `ADMIN_PASSWORD` in `.env`. To change the password, update
  `.env` and re-seed (it upserts the existing admin's password hash).

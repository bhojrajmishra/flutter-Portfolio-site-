-- Adds the small app/project icon and the short category label used by the
-- redesigned Projects window (Featured banner badge + list-row subtitle).
-- Safe to re-run: MySQL 8.0.29+ supports ADD COLUMN IF NOT EXISTS.
ALTER TABLE projects
  ADD COLUMN IF NOT EXISTS logo_url TEXT NULL AFTER image_url,
  ADD COLUMN IF NOT EXISTS category VARCHAR(100) NULL AFTER logo_url;

-- Portfolio backend schema (plain MySQL, no ORM/migration tool).
-- Apply once against a fresh database:
--   mysql -h <host> -u <user> -p <database> < sql/schema.sql

CREATE TABLE IF NOT EXISTS admin_users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Singleton row (id always 1).
CREATE TABLE IF NOT EXISTS hero_content (
  id INT PRIMARY KEY,
  name VARCHAR(255) NOT NULL DEFAULT 'Your Name',
  title VARCHAR(255) NOT NULL DEFAULT 'Software Engineer',
  subtitle VARCHAR(500) NOT NULL DEFAULT 'Building great things on the web and mobile.',
  summary TEXT NOT NULL,
  background_image_url TEXT NULL
);

-- Singleton row (id always 1).
CREATE TABLE IF NOT EXISTS about_content (
  id INT PRIMARY KEY,
  bio TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS skills (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(255) NOT NULL DEFAULT 'General',
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS projects (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  image_url TEXT NULL,
  tech_tags TEXT NOT NULL, -- JSON-encoded string array
  live_url TEXT NULL,
  repo_url TEXT NULL,
  featured TINYINT(1) NOT NULL DEFAULT 0,
  sort_order INT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS experience (
  id INT AUTO_INCREMENT PRIMARY KEY,
  company VARCHAR(255) NOT NULL,
  role VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  description TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS education (
  id INT AUTO_INCREMENT PRIMARY KEY,
  school VARCHAR(255) NOT NULL,
  degree VARCHAR(255) NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NULL,
  sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS social_links (
  id INT AUTO_INCREMENT PRIMARY KEY,
  platform VARCHAR(100) NOT NULL UNIQUE,
  url TEXT NOT NULL,
  -- Optional self-reported label shown as a badge on the desktop icon
  -- (e.g. "25+", "5K+"). Never computed/fabricated by the app — the admin
  -- types their own real number if they want one shown. NULL = no badge.
  badge_text VARCHAR(20) NULL
);

-- Only the most recently uploaded row (highest id/uploaded_at) is "current".
CREATE TABLE IF NOT EXISTS resume_files (
  id INT AUTO_INCREMENT PRIMARY KEY,
  filename VARCHAR(255) NOT NULL,
  url TEXT NOT NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Superseded by `apps` below (multiple listings instead of a single
-- "latest wins" row). Left in place, unused, rather than dropped —
-- nothing ever wrote a row that mattered here in production.
CREATE TABLE IF NOT EXISTS apk_files (
  id INT AUTO_INCREMENT PRIMARY KEY,
  filename VARCHAR(255) NOT NULL,
  version_label VARCHAR(50) NULL,
  url TEXT NOT NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- The App Store-style listing page: every row is a published app (not
-- just the latest one). `category` is validated against a fixed list on
-- the backend — keep APP_CATEGORIES in sync between
-- backend/src/routes/apps.ts and frontend/lib/core/models/app_listing.dart
-- if it ever changes.
CREATE TABLE IF NOT EXISTS apps (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL DEFAULT 'Other',
  description TEXT NULL,
  version_label VARCHAR(50) NULL,
  filename VARCHAR(255) NOT NULL,
  url TEXT NOT NULL,
  size_bytes BIGINT NULL,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS contact_messages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_read TINYINT(1) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS blog_posts (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) NOT NULL UNIQUE,
  excerpt TEXT NOT NULL,
  content TEXT NOT NULL, -- Markdown
  cover_image_url TEXT NULL,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

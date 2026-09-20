// One-off runner: applies a .sql file (plain statements, no DELIMITER
// tricks) against DATABASE_URL from this directory's .env. Usage:
//   node scripts/apply-migration.js sql/migrations/002_project_logo_category.sql
require("dotenv/config");
const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");

async function main() {
  const file = process.argv[2];
  if (!file) {
    console.error("Usage: node scripts/apply-migration.js <path-to-sql-file>");
    process.exit(1);
  }
  const sql = fs.readFileSync(path.resolve(file), "utf8");
  const pool = mysql.createPool({ uri: process.env.DATABASE_URL, multipleStatements: true });
  try {
    await pool.query(sql);
    console.log(`Applied ${file} successfully.`);
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error("Migration failed:", err.message);
  process.exit(1);
});

require("dotenv/config");
const mysql = require("mysql2/promise");

async function main() {
  const pool = mysql.createPool({ uri: process.env.DATABASE_URL });
  try {
    const [rows] = await pool.query(
      "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'projects' AND TABLE_SCHEMA = DATABASE() ORDER BY ORDINAL_POSITION"
    );
    console.log(rows.map((r) => r.COLUMN_NAME).join(", "));
  } finally {
    await pool.end();
  }
}

main();

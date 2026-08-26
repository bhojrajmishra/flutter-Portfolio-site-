import "dotenv/config";
import bcrypt from "bcryptjs";
import { RowDataPacket } from "mysql2";
import { pool } from "../lib/db";

async function main() {
  const adminEmail = process.env.ADMIN_EMAIL;
  const adminPassword = process.env.ADMIN_PASSWORD;

  if (!adminEmail || !adminPassword) {
    throw new Error("Set ADMIN_EMAIL and ADMIN_PASSWORD in backend/.env before seeding.");
  }

  const passwordHash = await bcrypt.hash(adminPassword, 12);
  await pool.query(
    `INSERT INTO admin_users (email, password_hash) VALUES (?, ?)
     ON DUPLICATE KEY UPDATE password_hash = VALUES(password_hash)`,
    [adminEmail, passwordHash]
  );
  console.log(`Admin user ready: ${adminEmail}`);

  await pool.query(
    `INSERT INTO hero_content (id, name, title, subtitle, summary)
     VALUES (1, 'Your Name', 'Software Engineer', 'I build fast, reliable apps for web and mobile.',
       'Edit this from the admin panel: a short summary of who you are, what you do, and what you''re looking for.')
     ON DUPLICATE KEY UPDATE id = id`
  );

  await pool.query(
    `INSERT INTO about_content (id, bio)
     VALUES (1, 'Edit this from the admin panel: a longer bio about your background, experience, and interests.')
     ON DUPLICATE KEY UPDATE id = id`
  );

  const [skillRows] = await pool.query<RowDataPacket[]>("SELECT COUNT(*) AS count FROM skills");
  if (skillRows[0].count === 0) {
    await pool.query(
      `INSERT INTO skills (name, category, sort_order) VALUES
        ('Flutter', 'Frameworks', 0),
        ('Dart', 'Languages', 1),
        ('TypeScript', 'Languages', 2),
        ('Node.js', 'Backend', 3),
        ('MySQL', 'Databases', 4)`
    );
  }

  const [projectRows] = await pool.query<RowDataPacket[]>("SELECT COUNT(*) AS count FROM projects");
  if (projectRows[0].count === 0) {
    await pool.query(
      `INSERT INTO projects (title, description, tech_tags, featured, sort_order) VALUES (?, ?, ?, ?, ?)`,
      [
        "Sample Project",
        "Replace this with a real project from the admin panel.",
        JSON.stringify(["Flutter", "Node.js", "MySQL"]),
        1,
        0,
      ]
    );
  }

  console.log("Seed complete. Placeholder content created — edit it via the admin panel.");
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await pool.end();
  });

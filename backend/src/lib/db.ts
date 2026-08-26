import mysql from "mysql2/promise";
import { env } from "./env";

// Plain mysql2 connection pool + raw SQL (no ORM/codegen step) — chosen over
// Prisma because this app runs on quota-constrained shared hosting where
// Prisma's client-generation step (engine binaries, generated code) can
// exceed the account's file-count quota. Query results are aliased to
// camelCase in each route so the JSON contract matches the frontend models
// exactly, unchanged from the original Prisma-based responses.
export const pool = mysql.createPool({
  uri: env.databaseUrl,
  waitForConnections: true,
  connectionLimit: 5,
  // DATE columns (start_date/end_date) hold calendar dates with no time
  // component. Without this, mysql2 hands back JS Date objects that get
  // interpreted in the server's local timezone, which then shift by a day
  // when serialized to ISO/UTC. Returning them as plain 'YYYY-MM-DD'
  // strings sidesteps timezone math entirely.
  dateStrings: ["DATE"],
});

import { Router } from "express";
import rateLimit from "express-rate-limit";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

// Public contact form is a common spam/abuse target — rate-limit it.
const submitLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many messages sent. Try again later." },
});

const contactSchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
  message: z.string().min(1).max(5000),
});

interface ContactRow extends RowDataPacket {
  id: number;
  name: string;
  email: string;
  message: string;
  createdAt: Date;
  isRead: number;
}

router.post(
  "/",
  submitLimiter,
  asyncHandler(async (req, res) => {
    const data = contactSchema.parse(req.body);
    const [result] = await pool.query<ResultSetHeader>(
      "INSERT INTO contact_messages (name, email, message) VALUES (?, ?, ?)",
      [data.name, data.email, data.message]
    );
    res.status(201).json({ id: result.insertId });
  })
);

// Admin inbox.
router.get(
  "/",
  requireAuth,
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<ContactRow[]>(
      "SELECT id, name, email, message, created_at AS createdAt, is_read AS isRead FROM contact_messages ORDER BY created_at DESC"
    );
    res.json(rows.map((r) => ({ ...r, isRead: Boolean(r.isRead) })));
  })
);

router.put(
  "/:id/read",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("UPDATE contact_messages SET is_read = 1 WHERE id = ?", [id]);
    const [rows] = await pool.query<ContactRow[]>(
      "SELECT id, name, email, message, created_at AS createdAt, is_read AS isRead FROM contact_messages WHERE id = ?",
      [id]
    );
    const row = rows[0];
    res.json(row ? { ...row, isRead: Boolean(row.isRead) } : null);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM contact_messages WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

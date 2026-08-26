import { Router } from "express";
import { RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface AboutRow extends RowDataPacket {
  id: number;
  bio: string;
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<AboutRow[]>("SELECT id, bio FROM about_content WHERE id = 1");
    res.json(rows[0] ?? null);
  })
);

const aboutSchema = z.object({
  bio: z.string().min(1),
});

router.put(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = aboutSchema.parse(req.body);
    await pool.query(
      `INSERT INTO about_content (id, bio) VALUES (1, ?)
       ON DUPLICATE KEY UPDATE bio = VALUES(bio)`,
      [data.bio]
    );
    const [rows] = await pool.query<AboutRow[]>("SELECT id, bio FROM about_content WHERE id = 1");
    res.json(rows[0]);
  })
);

export default router;

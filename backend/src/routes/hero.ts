import { Router } from "express";
import { RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface HeroRow extends RowDataPacket {
  id: number;
  name: string;
  title: string;
  subtitle: string;
  summary: string;
  backgroundImageUrl: string | null;
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<HeroRow[]>(
      "SELECT id, name, title, subtitle, summary, background_image_url AS backgroundImageUrl FROM hero_content WHERE id = 1"
    );
    res.json(rows[0] ?? null);
  })
);

const heroSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  subtitle: z.string().min(1),
  summary: z.string().min(1),
  backgroundImageUrl: z.string().url().optional().nullable(),
});

router.put(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = heroSchema.parse(req.body);
    await pool.query(
      `INSERT INTO hero_content (id, name, title, subtitle, summary, background_image_url)
       VALUES (1, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE name = VALUES(name), title = VALUES(title), subtitle = VALUES(subtitle),
         summary = VALUES(summary), background_image_url = VALUES(background_image_url)`,
      [data.name, data.title, data.subtitle, data.summary, data.backgroundImageUrl ?? null]
    );
    const [rows] = await pool.query<HeroRow[]>(
      "SELECT id, name, title, subtitle, summary, background_image_url AS backgroundImageUrl FROM hero_content WHERE id = 1"
    );
    res.json(rows[0]);
  })
);

export default router;

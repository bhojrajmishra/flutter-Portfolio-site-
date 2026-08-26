import { Router } from "express";
import { RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface SocialLinkRow extends RowDataPacket {
  id: number;
  platform: string;
  url: string;
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<SocialLinkRow[]>("SELECT id, platform, url FROM social_links ORDER BY platform ASC");
    res.json(rows);
  })
);

const socialLinkSchema = z.object({
  platform: z.string().min(1), // e.g. "github", "linkedin", "pubdev"
  url: z.string().url(),
});

// Upsert by platform: admin sets/updates the url for a given platform.
router.put(
  "/:platform",
  requireAuth,
  asyncHandler(async (req, res) => {
    const platform = req.params.platform;
    const { url } = socialLinkSchema.pick({ url: true }).parse(req.body);
    await pool.query(
      `INSERT INTO social_links (platform, url) VALUES (?, ?)
       ON DUPLICATE KEY UPDATE url = VALUES(url)`,
      [platform, url]
    );
    const [rows] = await pool.query<SocialLinkRow[]>("SELECT id, platform, url FROM social_links WHERE platform = ?", [
      platform,
    ]);
    res.json(rows[0]);
  })
);

router.delete(
  "/:platform",
  requireAuth,
  asyncHandler(async (req, res) => {
    await pool.query("DELETE FROM social_links WHERE platform = ?", [req.params.platform]);
    res.status(204).send();
  })
);

export default router;

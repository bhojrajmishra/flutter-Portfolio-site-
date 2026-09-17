import fs from "fs";
import path from "path";
import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { env } from "../lib/env";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";
import { uploadApp, UPLOADS_DIR } from "../lib/upload";

const router = Router();

// Keep in sync with frontend/lib/core/models/app_listing.dart's
// `appCategories` — the admin upload form's dropdown must offer exactly
// this list, since the backend rejects anything else.
export const APP_CATEGORIES = [
  "Productivity",
  "Utilities",
  "Tools",
  "Business",
  "Education",
  "Entertainment",
  "Social",
  "Health & Fitness",
  "Lifestyle",
  "Other",
] as const;

interface AppRow extends RowDataPacket {
  id: number;
  name: string;
  category: string;
  description: string | null;
  versionLabel: string | null;
  filename: string;
  url: string;
  sizeBytes: number | null;
  uploadedAt: Date;
}

const SELECT_COLUMNS = `id, name, category, description, version_label AS versionLabel,
  filename, url, size_bytes AS sizeBytes, uploaded_at AS uploadedAt`;

// Every published app — a real multi-listing store, not just "the latest
// upload wins" like the old single-slot apk_files table.
router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<AppRow[]>(`SELECT ${SELECT_COLUMNS} FROM apps ORDER BY uploaded_at DESC`);
    res.json(rows);
  })
);

const createSchema = z.object({
  name: z.string().min(1).max(255),
  category: z.enum(APP_CATEGORIES),
  description: z.string().max(2000).optional(),
  versionLabel: z.string().max(50).optional(),
});

router.post(
  "/",
  requireAuth,
  uploadApp.single("file"),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded (expected field name 'file')" });
    }
    // Multer already wrote the file to disk by this point. If anything
    // below fails (bad category, DB hiccup), clean it up rather than
    // leaving an orphaned file burning disk quota — that's exactly what
    // silently ate this account's quota and broke every upload after it.
    //
    // A large APK on a slow connection can also have its connection dropped
    // by the client/network *after* the file finished writing but before we
    // respond — nothing throws in that case (the DB insert below still runs
    // fine), so the try/catch alone doesn't cover it. Watch for the request
    // socket closing before we've actually sent a response, and clean up
    // then too.
    let responded = false;
    req.on("close", () => {
      if (!responded) fs.unlink(req.file!.path, () => {});
    });
    try {
      const data = createSchema.parse(req.body);
      const url = `${env.publicBaseUrl}/uploads/${req.file.filename}`;
      const [result] = await pool.query<ResultSetHeader>(
        `INSERT INTO apps (name, category, description, version_label, filename, url, size_bytes)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          data.name,
          data.category,
          data.description ?? null,
          data.versionLabel ?? null,
          req.file.originalname,
          url,
          req.file.size,
        ]
      );
      const [rows] = await pool.query<AppRow[]>(`SELECT ${SELECT_COLUMNS} FROM apps WHERE id = ?`, [result.insertId]);
      responded = true;
      res.status(201).json(rows[0]);
    } catch (err) {
      responded = true;
      fs.unlink(req.file.path, () => {});
      throw err;
    }
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const [rows] = await pool.query<AppRow[]>("SELECT url FROM apps WHERE id = ?", [id]);
    await pool.query("DELETE FROM apps WHERE id = ?", [id]);

    // Best-effort cleanup — disk quota on this hosting plan is small and
    // APKs are the biggest thing stored here. Never let a cleanup failure
    // fail the delete itself.
    const storedName = rows[0] ? path.basename(new URL(rows[0].url).pathname) : null;
    if (storedName) {
      fs.unlink(path.join(UPLOADS_DIR, storedName), () => {});
    }

    res.status(204).send();
  })
);

export default router;

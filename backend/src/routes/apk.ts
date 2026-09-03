import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { env } from "../lib/env";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";
import { uploadApk } from "../lib/upload";

const router = Router();

interface ApkRow extends RowDataPacket {
  id: number;
  filename: string;
  versionLabel: string | null;
  url: string;
  sizeBytes: number | null;
  uploadedAt: Date;
}

const SELECT_COLUMNS =
  "id, filename, version_label AS versionLabel, url, size_bytes AS sizeBytes, uploaded_at AS uploadedAt";

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<ApkRow[]>(`SELECT ${SELECT_COLUMNS} FROM apk_files ORDER BY uploaded_at DESC LIMIT 1`);
    res.json(rows[0] ?? null);
  })
);

const versionLabelSchema = z.string().max(50).optional();

router.post(
  "/",
  requireAuth,
  uploadApk.single("file"),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded (expected field name 'file')" });
    }
    const versionLabel = versionLabelSchema.parse(req.body.versionLabel) ?? null;
    const url = `${env.publicBaseUrl}/uploads/${req.file.filename}`;
    const [result] = await pool.query<ResultSetHeader>(
      "INSERT INTO apk_files (filename, version_label, url, size_bytes) VALUES (?, ?, ?, ?)",
      [req.file.originalname, versionLabel, url, req.file.size]
    );
    const [rows] = await pool.query<ApkRow[]>(`SELECT ${SELECT_COLUMNS} FROM apk_files WHERE id = ?`, [
      result.insertId,
    ]);
    res.status(201).json(rows[0]);
  })
);

export default router;

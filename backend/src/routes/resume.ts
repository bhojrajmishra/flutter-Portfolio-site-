import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { env } from "../lib/env";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";
import { uploadResume } from "../lib/upload";

const router = Router();

interface ResumeRow extends RowDataPacket {
  id: number;
  filename: string;
  url: string;
  uploadedAt: Date;
}

const SELECT_COLUMNS = "id, filename, url, uploaded_at AS uploadedAt";

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<ResumeRow[]>(
      `SELECT ${SELECT_COLUMNS} FROM resume_files ORDER BY uploaded_at DESC LIMIT 1`
    );
    res.json(rows[0] ?? null);
  })
);

router.post(
  "/",
  requireAuth,
  uploadResume.single("file"),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded (expected field name 'file')" });
    }
    const url = `${env.publicBaseUrl}/uploads/${req.file.filename}`;
    const [result] = await pool.query<ResultSetHeader>("INSERT INTO resume_files (filename, url) VALUES (?, ?)", [
      req.file.originalname,
      url,
    ]);
    const [rows] = await pool.query<ResumeRow[]>(`SELECT ${SELECT_COLUMNS} FROM resume_files WHERE id = ?`, [
      result.insertId,
    ]);
    res.status(201).json(rows[0]);
  })
);

export default router;

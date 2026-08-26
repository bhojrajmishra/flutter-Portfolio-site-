import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface SkillRow extends RowDataPacket {
  id: number;
  name: string;
  category: string;
  sortOrder: number;
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<SkillRow[]>(
      "SELECT id, name, category, sort_order AS sortOrder FROM skills ORDER BY sort_order ASC"
    );
    res.json(rows);
  })
);

const skillSchema = z.object({
  name: z.string().min(1),
  category: z.string().min(1).default("General"),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = skillSchema.parse(req.body);
    const [result] = await pool.query<ResultSetHeader>(
      "INSERT INTO skills (name, category, sort_order) VALUES (?, ?, ?)",
      [data.name, data.category, data.sortOrder]
    );
    res.status(201).json({ id: result.insertId, ...data });
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = skillSchema.partial().parse(req.body);
    const fields: string[] = [];
    const values: unknown[] = [];
    if (data.name !== undefined) { fields.push("name = ?"); values.push(data.name); }
    if (data.category !== undefined) { fields.push("category = ?"); values.push(data.category); }
    if (data.sortOrder !== undefined) { fields.push("sort_order = ?"); values.push(data.sortOrder); }
    if (fields.length > 0) {
      await pool.query(`UPDATE skills SET ${fields.join(", ")} WHERE id = ?`, [...values, id]);
    }
    const [rows] = await pool.query<SkillRow[]>(
      "SELECT id, name, category, sort_order AS sortOrder FROM skills WHERE id = ?",
      [id]
    );
    res.json(rows[0]);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM skills WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

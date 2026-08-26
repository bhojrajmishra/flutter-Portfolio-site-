import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { dateOnly } from "../lib/dateOnly";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface ExperienceRow extends RowDataPacket {
  id: number;
  company: string;
  role: string;
  startDate: string;
  endDate: string | null;
  description: string;
  sortOrder: number;
}

const SELECT_COLUMNS = `id, company, role, start_date AS startDate, end_date AS endDate, description,
  sort_order AS sortOrder`;

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<ExperienceRow[]>(`SELECT ${SELECT_COLUMNS} FROM experience ORDER BY sort_order ASC`);
    res.json(rows);
  })
);

const experienceSchema = z.object({
  company: z.string().min(1),
  role: z.string().min(1),
  startDate: dateOnly,
  endDate: dateOnly.optional().nullable(),
  description: z.string().min(1),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = experienceSchema.parse(req.body);
    const [result] = await pool.query<ResultSetHeader>(
      "INSERT INTO experience (company, role, start_date, end_date, description, sort_order) VALUES (?, ?, ?, ?, ?, ?)",
      [data.company, data.role, data.startDate, data.endDate ?? null, data.description, data.sortOrder]
    );
    const [rows] = await pool.query<ExperienceRow[]>(`SELECT ${SELECT_COLUMNS} FROM experience WHERE id = ?`, [
      result.insertId,
    ]);
    res.status(201).json(rows[0]);
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = experienceSchema.partial().parse(req.body);

    const columnMap: Record<string, [string, unknown]> = {};
    if (data.company !== undefined) columnMap.company = ["company = ?", data.company];
    if (data.role !== undefined) columnMap.role = ["role = ?", data.role];
    if (data.startDate !== undefined) columnMap.startDate = ["start_date = ?", data.startDate];
    if (data.endDate !== undefined) columnMap.endDate = ["end_date = ?", data.endDate];
    if (data.description !== undefined) columnMap.description = ["description = ?", data.description];
    if (data.sortOrder !== undefined) columnMap.sortOrder = ["sort_order = ?", data.sortOrder];

    const entries = Object.values(columnMap);
    if (entries.length > 0) {
      const setClause = entries.map(([clause]) => clause).join(", ");
      const values = entries.map(([, value]) => value);
      await pool.query(`UPDATE experience SET ${setClause} WHERE id = ?`, [...values, id]);
    }

    const [rows] = await pool.query<ExperienceRow[]>(`SELECT ${SELECT_COLUMNS} FROM experience WHERE id = ?`, [id]);
    res.json(rows[0]);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM experience WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { dateOnly } from "../lib/dateOnly";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface EducationRow extends RowDataPacket {
  id: number;
  school: string;
  degree: string;
  startDate: string;
  endDate: string | null;
  sortOrder: number;
}

const SELECT_COLUMNS = `id, school, degree, start_date AS startDate, end_date AS endDate, sort_order AS sortOrder`;

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<EducationRow[]>(`SELECT ${SELECT_COLUMNS} FROM education ORDER BY sort_order ASC`);
    res.json(rows);
  })
);

const educationSchema = z.object({
  school: z.string().min(1),
  degree: z.string().min(1),
  startDate: dateOnly,
  endDate: dateOnly.optional().nullable(),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = educationSchema.parse(req.body);
    const [result] = await pool.query<ResultSetHeader>(
      "INSERT INTO education (school, degree, start_date, end_date, sort_order) VALUES (?, ?, ?, ?, ?)",
      [data.school, data.degree, data.startDate, data.endDate ?? null, data.sortOrder]
    );
    const [rows] = await pool.query<EducationRow[]>(`SELECT ${SELECT_COLUMNS} FROM education WHERE id = ?`, [
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
    const data = educationSchema.partial().parse(req.body);

    const columnMap: Record<string, [string, unknown]> = {};
    if (data.school !== undefined) columnMap.school = ["school = ?", data.school];
    if (data.degree !== undefined) columnMap.degree = ["degree = ?", data.degree];
    if (data.startDate !== undefined) columnMap.startDate = ["start_date = ?", data.startDate];
    if (data.endDate !== undefined) columnMap.endDate = ["end_date = ?", data.endDate];
    if (data.sortOrder !== undefined) columnMap.sortOrder = ["sort_order = ?", data.sortOrder];

    const entries = Object.values(columnMap);
    if (entries.length > 0) {
      const setClause = entries.map(([clause]) => clause).join(", ");
      const values = entries.map(([, value]) => value);
      await pool.query(`UPDATE education SET ${setClause} WHERE id = ?`, [...values, id]);
    }

    const [rows] = await pool.query<EducationRow[]>(`SELECT ${SELECT_COLUMNS} FROM education WHERE id = ?`, [id]);
    res.json(rows[0]);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM education WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

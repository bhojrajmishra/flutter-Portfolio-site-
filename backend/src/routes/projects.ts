import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface ProjectRow extends RowDataPacket {
  id: number;
  title: string;
  description: string;
  imageUrl: string | null;
  logoUrl: string | null;
  category: string | null;
  techTags: string;
  liveUrl: string | null;
  repoUrl: string | null;
  featured: number;
  sortOrder: number;
  createdAt: Date;
}

const SELECT_COLUMNS = `id, title, description, image_url AS imageUrl, logo_url AS logoUrl, category,
  tech_tags AS techTags, live_url AS liveUrl, repo_url AS repoUrl, featured, sort_order AS sortOrder,
  created_at AS createdAt`;

function serialize(row: ProjectRow) {
  return { ...row, techTags: JSON.parse(row.techTags || "[]"), featured: Boolean(row.featured) };
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<ProjectRow[]>(`SELECT ${SELECT_COLUMNS} FROM projects ORDER BY sort_order ASC`);
    res.json(rows.map(serialize));
  })
);

const projectSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  imageUrl: z.string().url().optional().nullable(),
  logoUrl: z.string().url().optional().nullable(),
  category: z.string().max(100).optional().nullable(),
  techTags: z.array(z.string()).default([]),
  liveUrl: z.string().url().optional().nullable(),
  repoUrl: z.string().url().optional().nullable(),
  featured: z.boolean().default(false),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = projectSchema.parse(req.body);
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO projects (title, description, image_url, logo_url, category, tech_tags, live_url, repo_url, featured, sort_order)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        data.title,
        data.description,
        data.imageUrl ?? null,
        data.logoUrl ?? null,
        data.category ?? null,
        JSON.stringify(data.techTags),
        data.liveUrl ?? null,
        data.repoUrl ?? null,
        data.featured ? 1 : 0,
        data.sortOrder,
      ]
    );
    const [rows] = await pool.query<ProjectRow[]>(`SELECT ${SELECT_COLUMNS} FROM projects WHERE id = ?`, [
      result.insertId,
    ]);
    res.status(201).json(serialize(rows[0]));
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = projectSchema.partial().parse(req.body);

    const columnMap: Record<string, [string, unknown]> = {};
    if (data.title !== undefined) columnMap.title = ["title = ?", data.title];
    if (data.description !== undefined) columnMap.description = ["description = ?", data.description];
    if (data.imageUrl !== undefined) columnMap.imageUrl = ["image_url = ?", data.imageUrl];
    if (data.logoUrl !== undefined) columnMap.logoUrl = ["logo_url = ?", data.logoUrl];
    if (data.category !== undefined) columnMap.category = ["category = ?", data.category];
    if (data.techTags !== undefined) columnMap.techTags = ["tech_tags = ?", JSON.stringify(data.techTags)];
    if (data.liveUrl !== undefined) columnMap.liveUrl = ["live_url = ?", data.liveUrl];
    if (data.repoUrl !== undefined) columnMap.repoUrl = ["repo_url = ?", data.repoUrl];
    if (data.featured !== undefined) columnMap.featured = ["featured = ?", data.featured ? 1 : 0];
    if (data.sortOrder !== undefined) columnMap.sortOrder = ["sort_order = ?", data.sortOrder];

    const entries = Object.values(columnMap);
    if (entries.length > 0) {
      const setClause = entries.map(([clause]) => clause).join(", ");
      const values = entries.map(([, value]) => value);
      await pool.query(`UPDATE projects SET ${setClause} WHERE id = ?`, [...values, id]);
    }

    const [rows] = await pool.query<ProjectRow[]>(`SELECT ${SELECT_COLUMNS} FROM projects WHERE id = ?`, [id]);
    res.json(serialize(rows[0]));
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM projects WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

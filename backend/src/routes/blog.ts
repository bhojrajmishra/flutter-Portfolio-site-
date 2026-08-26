import { Router } from "express";
import { ResultSetHeader, RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface BlogPostRow extends RowDataPacket {
  id: number;
  title: string;
  slug: string;
  excerpt: string;
  content: string;
  imageUrl: string | null;
  isPublished: number;
  createdAt: Date;
  updatedAt: Date;
}

const SELECT_COLUMNS = `id, title, slug, excerpt, content, cover_image_url AS imageUrl,
  is_published AS isPublished, created_at AS createdAt, updated_at AS updatedAt`;

function serialize(row: BlogPostRow) {
  return { ...row, isPublished: Boolean(row.isPublished) };
}

function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 200);
}

// Returns every post — the admin panel needs drafts too; the public Blog
// window filters to isPublished client-side.
router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<BlogPostRow[]>(`SELECT ${SELECT_COLUMNS} FROM blog_posts ORDER BY created_at DESC`);
    res.json(rows.map(serialize));
  })
);

const blogPostSchema = z.object({
  title: z.string().min(1),
  slug: z.string().min(1).optional(),
  excerpt: z.string().min(1),
  content: z.string().min(1),
  imageUrl: z.string().url().optional().nullable(),
  isPublished: z.boolean().default(true),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = blogPostSchema.parse(req.body);
    const slug = slugify(data.slug || data.title);
    const [result] = await pool.query<ResultSetHeader>(
      `INSERT INTO blog_posts (title, slug, excerpt, content, cover_image_url, is_published)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [data.title, slug, data.excerpt, data.content, data.imageUrl ?? null, data.isPublished ? 1 : 0]
    );
    const [rows] = await pool.query<BlogPostRow[]>(`SELECT ${SELECT_COLUMNS} FROM blog_posts WHERE id = ?`, [
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
    const data = blogPostSchema.partial().parse(req.body);

    const columnMap: Record<string, [string, unknown]> = {};
    if (data.title !== undefined) columnMap.title = ["title = ?", data.title];
    if (data.slug !== undefined) columnMap.slug = ["slug = ?", slugify(data.slug)];
    if (data.excerpt !== undefined) columnMap.excerpt = ["excerpt = ?", data.excerpt];
    if (data.content !== undefined) columnMap.content = ["content = ?", data.content];
    if (data.imageUrl !== undefined) columnMap.imageUrl = ["cover_image_url = ?", data.imageUrl];
    if (data.isPublished !== undefined) columnMap.isPublished = ["is_published = ?", data.isPublished ? 1 : 0];

    const entries = Object.values(columnMap);
    if (entries.length > 0) {
      const setClause = entries.map(([clause]) => clause).join(", ");
      const values = entries.map(([, value]) => value);
      await pool.query(`UPDATE blog_posts SET ${setClause} WHERE id = ?`, [...values, id]);
    }

    const [rows] = await pool.query<BlogPostRow[]>(`SELECT ${SELECT_COLUMNS} FROM blog_posts WHERE id = ?`, [id]);
    res.json(serialize(rows[0]));
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await pool.query("DELETE FROM blog_posts WHERE id = ?", [id]);
    res.status(204).send();
  })
);

export default router;

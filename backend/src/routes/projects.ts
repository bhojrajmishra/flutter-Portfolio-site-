import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

function serialize(project: { techTags: string; [k: string]: unknown }) {
  return { ...project, techTags: JSON.parse(project.techTags || "[]") };
}

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const projects = await prisma.project.findMany({ orderBy: { sortOrder: "asc" } });
    res.json(projects.map(serialize));
  })
);

const projectSchema = z.object({
  title: z.string().min(1),
  description: z.string().min(1),
  imageUrl: z.string().url().optional().nullable(),
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
    const { techTags, ...data } = projectSchema.parse(req.body);
    const project = await prisma.project.create({
      data: { ...data, techTags: JSON.stringify(techTags) },
    });
    res.status(201).json(serialize(project));
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const { techTags, ...data } = projectSchema.partial().parse(req.body);
    const project = await prisma.project.update({
      where: { id },
      data: { ...data, ...(techTags !== undefined ? { techTags: JSON.stringify(techTags) } : {}) },
    });
    res.json(serialize(project));
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await prisma.project.delete({ where: { id } });
    res.status(204).send();
  })
);

export default router;

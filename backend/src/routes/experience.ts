import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const experience = await prisma.experience.findMany({ orderBy: { sortOrder: "asc" } });
    res.json(experience);
  })
);

const experienceSchema = z.object({
  company: z.string().min(1),
  role: z.string().min(1),
  startDate: z.coerce.date(),
  endDate: z.coerce.date().optional().nullable(),
  description: z.string().min(1),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = experienceSchema.parse(req.body);
    const entry = await prisma.experience.create({ data });
    res.status(201).json(entry);
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = experienceSchema.partial().parse(req.body);
    const entry = await prisma.experience.update({ where: { id }, data });
    res.json(entry);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await prisma.experience.delete({ where: { id } });
    res.status(204).send();
  })
);

export default router;

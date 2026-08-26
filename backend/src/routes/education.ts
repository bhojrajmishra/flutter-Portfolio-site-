import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const education = await prisma.education.findMany({ orderBy: { sortOrder: "asc" } });
    res.json(education);
  })
);

const educationSchema = z.object({
  school: z.string().min(1),
  degree: z.string().min(1),
  startDate: z.coerce.date(),
  endDate: z.coerce.date().optional().nullable(),
  sortOrder: z.number().int().default(0),
});

router.post(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = educationSchema.parse(req.body);
    const entry = await prisma.education.create({ data });
    res.status(201).json(entry);
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = educationSchema.partial().parse(req.body);
    const entry = await prisma.education.update({ where: { id }, data });
    res.json(entry);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await prisma.education.delete({ where: { id } });
    res.status(204).send();
  })
);

export default router;

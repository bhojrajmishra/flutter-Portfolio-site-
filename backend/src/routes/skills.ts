import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const skills = await prisma.skill.findMany({ orderBy: { sortOrder: "asc" } });
    res.json(skills);
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
    const skill = await prisma.skill.create({ data });
    res.status(201).json(skill);
  })
);

router.put(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const data = skillSchema.partial().parse(req.body);
    const skill = await prisma.skill.update({ where: { id }, data });
    res.json(skill);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await prisma.skill.delete({ where: { id } });
    res.status(204).send();
  })
);

export default router;

import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const hero = await prisma.heroContent.findUnique({ where: { id: 1 } });
    res.json(hero);
  })
);

const heroSchema = z.object({
  name: z.string().min(1),
  title: z.string().min(1),
  subtitle: z.string().min(1),
  summary: z.string().min(1),
  backgroundImageUrl: z.string().url().optional().nullable(),
});

router.put(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = heroSchema.parse(req.body);
    const hero = await prisma.heroContent.upsert({
      where: { id: 1 },
      create: { id: 1, ...data },
      update: data,
    });
    res.json(hero);
  })
);

export default router;

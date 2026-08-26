import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const about = await prisma.aboutContent.findUnique({ where: { id: 1 } });
    res.json(about);
  })
);

const aboutSchema = z.object({
  bio: z.string().min(1),
});

router.put(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = aboutSchema.parse(req.body);
    const about = await prisma.aboutContent.upsert({
      where: { id: 1 },
      create: { id: 1, ...data },
      update: data,
    });
    res.json(about);
  })
);

export default router;

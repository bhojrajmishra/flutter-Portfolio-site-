import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const links = await prisma.socialLink.findMany({ orderBy: { platform: "asc" } });
    res.json(links);
  })
);

const socialLinkSchema = z.object({
  platform: z.string().min(1), // e.g. "github", "linkedin", "pubdev"
  url: z.string().url(),
});

// Upsert by platform: admin sets/updates the url for a given platform.
router.put(
  "/:platform",
  requireAuth,
  asyncHandler(async (req, res) => {
    const platform = req.params.platform;
    const { url } = socialLinkSchema.pick({ url: true }).parse(req.body);
    const link = await prisma.socialLink.upsert({
      where: { platform },
      create: { platform, url },
      update: { url },
    });
    res.json(link);
  })
);

router.delete(
  "/:platform",
  requireAuth,
  asyncHandler(async (req, res) => {
    await prisma.socialLink.delete({ where: { platform: req.params.platform } });
    res.status(204).send();
  })
);

export default router;

import { Router } from "express";
import { env } from "../lib/env";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";
import { uploadResume } from "../lib/upload";

const router = Router();

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const latest = await prisma.resumeFile.findFirst({ orderBy: { uploadedAt: "desc" } });
    res.json(latest);
  })
);

router.post(
  "/",
  requireAuth,
  uploadResume.single("file"),
  asyncHandler(async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: "No file uploaded (expected field name 'file')" });
    }
    const url = `${env.publicBaseUrl}/uploads/${req.file.filename}`;
    const resume = await prisma.resumeFile.create({
      data: { filename: req.file.originalname, url },
    });
    res.status(201).json(resume);
  })
);

export default router;

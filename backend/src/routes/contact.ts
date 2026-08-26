import { Router } from "express";
import rateLimit from "express-rate-limit";
import { z } from "zod";
import { prisma } from "../lib/prisma";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

// Public contact form is a common spam/abuse target — rate-limit it.
const submitLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many messages sent. Try again later." },
});

const contactSchema = z.object({
  name: z.string().min(1).max(200),
  email: z.string().email(),
  message: z.string().min(1).max(5000),
});

router.post(
  "/",
  submitLimiter,
  asyncHandler(async (req, res) => {
    const data = contactSchema.parse(req.body);
    const entry = await prisma.contactMessage.create({ data });
    res.status(201).json({ id: entry.id });
  })
);

// Admin inbox.
router.get(
  "/",
  requireAuth,
  asyncHandler(async (_req, res) => {
    const messages = await prisma.contactMessage.findMany({ orderBy: { createdAt: "desc" } });
    res.json(messages);
  })
);

router.put(
  "/:id/read",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    const message = await prisma.contactMessage.update({ where: { id }, data: { isRead: true } });
    res.json(message);
  })
);

router.delete(
  "/:id",
  requireAuth,
  asyncHandler(async (req, res) => {
    const id = Number(req.params.id);
    await prisma.contactMessage.delete({ where: { id } });
    res.status(204).send();
  })
);

export default router;

import bcrypt from "bcryptjs";
import { Router } from "express";
import rateLimit from "express-rate-limit";
import jwt from "jsonwebtoken";
import { RowDataPacket } from "mysql2";
import { z } from "zod";
import { env } from "../lib/env";
import { pool } from "../lib/db";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

// Slow down brute-force attempts against the single admin account.
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many login attempts. Try again later." },
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

interface AdminRow extends RowDataPacket {
  id: number;
  email: string;
  password_hash: string;
}

router.post(
  "/login",
  loginLimiter,
  asyncHandler(async (req, res) => {
    const { email, password } = loginSchema.parse(req.body);

    const [rows] = await pool.query<AdminRow[]>("SELECT id, email, password_hash FROM admin_users WHERE email = ?", [
      email,
    ]);
    const admin = rows[0];
    if (!admin) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    const valid = await bcrypt.compare(password, admin.password_hash);
    if (!valid) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    const token = jwt.sign({ adminId: admin.id }, env.jwtSecret, { expiresIn: env.jwtExpiresIn } as jwt.SignOptions);
    res.json({ token, email: admin.email });
  })
);

export default router;

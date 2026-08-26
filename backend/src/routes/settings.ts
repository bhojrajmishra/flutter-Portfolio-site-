import { Router } from "express";
import { RowDataPacket } from "mysql2";
import { z } from "zod";
import { pool } from "../lib/db";
import { requireAuth } from "../middleware/auth";
import { asyncHandler } from "../middleware/errorHandler";

const router = Router();

interface SettingsRow extends RowDataPacket {
  id: number;
  weatherCity: string;
  weatherLat: number;
  weatherLon: number;
}

const SELECT_COLUMNS =
  "id, weather_city AS weatherCity, weather_lat AS weatherLat, weather_lon AS weatherLon";

router.get(
  "/",
  asyncHandler(async (_req, res) => {
    const [rows] = await pool.query<SettingsRow[]>(`SELECT ${SELECT_COLUMNS} FROM site_settings WHERE id = 1`);
    res.json(rows[0] ?? null);
  })
);

const settingsSchema = z.object({
  weatherCity: z.string().min(1),
  weatherLat: z.number().min(-90).max(90),
  weatherLon: z.number().min(-180).max(180),
});

router.put(
  "/",
  requireAuth,
  asyncHandler(async (req, res) => {
    const data = settingsSchema.parse(req.body);
    await pool.query(
      `INSERT INTO site_settings (id, weather_city, weather_lat, weather_lon)
       VALUES (1, ?, ?, ?)
       ON DUPLICATE KEY UPDATE weather_city = VALUES(weather_city), weather_lat = VALUES(weather_lat),
         weather_lon = VALUES(weather_lon)`,
      [data.weatherCity, data.weatherLat, data.weatherLon]
    );
    const [rows] = await pool.query<SettingsRow[]>(`SELECT ${SELECT_COLUMNS} FROM site_settings WHERE id = 1`);
    res.json(rows[0]);
  })
);

export default router;

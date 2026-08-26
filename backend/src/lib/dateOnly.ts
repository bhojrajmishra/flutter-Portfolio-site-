import { z } from "zod";

/**
 * Accepts any ISO-8601-ish date/datetime string (the frontend sends
 * DateTime.toIso8601String(), e.g. "2022-01-15T00:00:00.000") and keeps only
 * the "YYYY-MM-DD" calendar date, dropping any time/timezone component.
 * Stored and returned as a plain string throughout — never converted to a
 * JS Date — so no timezone offset can shift the calendar day.
 */
export const dateOnly = z
  .string()
  .transform((s) => s.slice(0, 10))
  .refine((s) => /^\d{4}-\d{2}-\d{2}$/.test(s), "Expected a date like YYYY-MM-DD");

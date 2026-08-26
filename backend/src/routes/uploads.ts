import { Router } from "express";
import { env } from "../lib/env";
import { requireAuth } from "../middleware/auth";
import { uploadImage } from "../lib/upload";

const router = Router();

// Generic image upload used by admin forms (hero background, project thumbnails, ...).
// Returns the public URL to store on the relevant resource.
router.post("/image", requireAuth, uploadImage.single("file"), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: "No file uploaded (expected field name 'file')" });
  }
  const url = `${env.publicBaseUrl}/uploads/${req.file.filename}`;
  res.status(201).json({ url });
});

export default router;

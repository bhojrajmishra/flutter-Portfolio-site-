import cors from "cors";
import express from "express";
import helmet from "helmet";
import { env } from "./lib/env";
import { UPLOADS_DIR } from "./lib/upload";
import { errorHandler } from "./middleware/errorHandler";

import aboutRouter from "./routes/about";
import apkRouter from "./routes/apk";
import authRouter from "./routes/auth";
import blogRouter from "./routes/blog";
import contactRouter from "./routes/contact";
import educationRouter from "./routes/education";
import experienceRouter from "./routes/experience";
import heroRouter from "./routes/hero";
import projectsRouter from "./routes/projects";
import resumeRouter from "./routes/resume";
import skillsRouter from "./routes/skills";
import socialLinksRouter from "./routes/socialLinks";
import uploadsRouter from "./routes/uploads";

export const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(
  cors({
    origin: env.corsOrigins.length > 0 ? env.corsOrigins : true,
  })
);
app.use(express.json({ limit: "2mb" }));

// Uploaded images/resume served statically. In prod, Nginx serves this path directly
// and this line is a local-dev fallback / safety net.
app.use("/uploads", express.static(UPLOADS_DIR));

app.get("/api/health", (_req, res) => res.json({ status: "ok" }));

app.use("/api/auth", authRouter);
app.use("/api/apk", apkRouter);
app.use("/api/blog", blogRouter);
app.use("/api/hero", heroRouter);
app.use("/api/about", aboutRouter);
app.use("/api/skills", skillsRouter);
app.use("/api/projects", projectsRouter);
app.use("/api/experience", experienceRouter);
app.use("/api/education", educationRouter);
app.use("/api/social-links", socialLinksRouter);
app.use("/api/resume", resumeRouter);
app.use("/api/contact", contactRouter);
app.use("/api/uploads", uploadsRouter);

app.use((_req, res) => res.status(404).json({ error: "Not found" }));
app.use(errorHandler);

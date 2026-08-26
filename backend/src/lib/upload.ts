import fs from "fs";
import multer from "multer";
import path from "path";

// Deliberately NOT __dirname-relative: __dirname points at dist/src/lib when
// running the compiled build (one directory deeper than when ts-node-dev runs
// the .ts source directly for local dev), which silently wrote uploads into
// dist/uploads in production — wiped on every redeploy since dist/ is
// recreated from scratch each time. process.cwd() is reliable in both cases:
// npm scripts and the alwaysdata Node.js Site's "Working directory" both run
// with cwd set to backend/.
export const UPLOADS_DIR = path.join(process.cwd(), "uploads");

if (!fs.existsSync(UPLOADS_DIR)) {
  fs.mkdirSync(UPLOADS_DIR, { recursive: true });
}

function sanitizeExt(originalName: string): string {
  const ext = path.extname(originalName).toLowerCase();
  return /^\.[a-z0-9]{1,5}$/.test(ext) ? ext : "";
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOADS_DIR),
  filename: (_req, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${sanitizeExt(file.originalname)}`);
  },
});

const IMAGE_TYPES = new Set(["image/png", "image/jpeg", "image/webp", "image/gif", "image/svg+xml"]);
const PDF_TYPE = "application/pdf";

export const uploadImage = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 }, // 8MB
  fileFilter: (_req, file, cb) => {
    if (!IMAGE_TYPES.has(file.mimetype)) {
      return cb(new Error("Only image files (png, jpg, webp, gif, svg) are allowed"));
    }
    cb(null, true);
  },
});

export const uploadResume = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 }, // 15MB
  fileFilter: (_req, file, cb) => {
    if (file.mimetype !== PDF_TYPE) {
      return cb(new Error("Only PDF files are allowed for the resume"));
    }
    cb(null, true);
  },
});

// Browsers/OSes don't consistently label .apk files — accept the registered
// type and the generic fallback some upload from actually sends.
const APK_TYPES = new Set(["application/vnd.android.package-archive", "application/octet-stream"]);

export const uploadApk = multer({
  storage,
  // Keep this modest — shared hosting disk quota here is small (~200MB
  // total for the whole account). A large APK eats it fast.
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
  fileFilter: (_req, file, cb) => {
    const isApkExt = file.originalname.toLowerCase().endsWith(".apk");
    if (!APK_TYPES.has(file.mimetype) || !isApkExt) {
      return cb(new Error("Only .apk files are allowed"));
    }
    cb(null, true);
  },
});

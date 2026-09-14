import { app } from "./app";
import { env } from "./lib/env";

// Safety net for aborted requests (e.g. a large APK upload interrupted
// mid-stream by a flaky connection): multer/busboy's internal write stream
// can emit an 'error' event nothing else listens for, which by default
// crashes the whole Node process — taking down every other visitor's
// request too, not just the failed upload. Log and keep serving instead.
process.on("uncaughtException", (err) => {
  console.error("uncaughtException (request survives, process kept alive):", err);
});
process.on("unhandledRejection", (err) => {
  console.error("unhandledRejection (request survives, process kept alive):", err);
});

const listeningMessage = `Portfolio API listening on http://${env.host ?? "localhost"}:${env.port}`;

if (env.host) {
  // Shared hosting (e.g. alwaysdata) requires binding to the exact assigned IP.
  app.listen(env.port, env.host, () => console.log(listeningMessage));
} else {
  app.listen(env.port, () => console.log(listeningMessage));
}

import { app } from "./app";
import { env } from "./lib/env";

const listeningMessage = `Portfolio API listening on http://${env.host ?? "localhost"}:${env.port}`;

if (env.host) {
  // Shared hosting (e.g. alwaysdata) requires binding to the exact assigned IP.
  app.listen(env.port, env.host, () => console.log(listeningMessage));
} else {
  app.listen(env.port, () => console.log(listeningMessage));
}

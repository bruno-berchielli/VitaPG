#!/usr/bin/env node
// Esbuild runs in three modes:
//
// `yarn build`          - build once and exit
// `yarn build --watch`  - rebuild on change
// `yarn build --reload` - rebuild and live-reload the browser on views/JS/CSS changes
//
// The esbuild-rails plugin resolves glob imports, which is what auto-registers
// every ViewComponent sidecar Stimulus controller (see app/components/index.js).

import * as esbuild from "esbuild";
import path from "path";
import rails from "esbuild-rails";
import chokidar from "chokidar";
import http from "http";
import { setTimeout } from "timers/promises";

const clients = [];
const entryPoints = ["application.js"];
const watchDirectories = [
  "./app/javascript",
  "./app/components",
  "./app/views",
  "./app/assets/builds", // Wait for cssbundling changes
];
const config = {
  absWorkingDir: path.join(process.cwd(), "app/javascript"),
  bundle: true,
  entryPoints: entryPoints,
  minify: process.env.RAILS_ENV == "production",
  outdir: path.join(process.cwd(), "app/assets/builds"),
  plugins: [rails()],
  sourcemap: process.env.RAILS_ENV != "production",
};

async function buildAndReload() {
  // Foreman assigns a separate PORT for each process
  const port = parseInt(process.env.PORT);
  const context = await esbuild.context({
    ...config,
    banner: {
      js: ` (() => new EventSource("http://localhost:${port}").onmessage = () => location.reload())();`,
    },
  });

  // Reload uses an HTTP server as an event stream to reload the browser
  http
    .createServer((req, res) => {
      return clients.push(
        res.writeHead(200, {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          "Access-Control-Allow-Origin": "*",
          Connection: "keep-alive",
        }),
      );
    })
    .listen(port);

  await context.rebuild();
  console.log("[reload] initial build succeeded");

  let ready = false;
  chokidar
    .watch(watchDirectories)
    .on("ready", () => {
      console.log("[reload] ready");
      ready = true;
    })
    .on("all", async (event, changedPath) => {
      if (ready === false) return;

      if (changedPath.includes("javascript") || changedPath.includes("components")) {
        try {
          await setTimeout(20);
          await context.rebuild();
          console.log("[reload] build succeeded");
        } catch (error) {
          console.error("[reload] build failed", error);
        }
      }
      clients.forEach((res) => res.write("data: update\n\n"));
      clients.length = 0;
    });
}

if (process.argv.includes("--reload")) {
  buildAndReload();
} else if (process.argv.includes("--watch")) {
  let context = await esbuild.context({ ...config, logLevel: "info" });
  context.watch();
} else {
  esbuild.build(config);
}

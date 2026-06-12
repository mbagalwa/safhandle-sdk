#!/usr/bin/env node
/**
 * Runs npm audit when a lockfile exists; skips otherwise.
 */
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const lockfile = join(root, "package-lock.json");

if (!existsSync(lockfile)) {
  console.log("No package-lock.json: skipping dependency audit.");
  process.exit(0);
}

const result = spawnSync("npm", ["audit", "--audit-level=high"], {
  stdio: "inherit",
  cwd: root,
});

process.exit(result.status ?? 1);

import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;

test("package.json declares MIT license", () => {
  const pkg = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
  assert.equal(pkg.license, "MIT");
  assert.match(pkg.repository.url, /saflink-sdk/);
  assert.equal(pkg.name, "@safrochain/saflink");
});

test("CI workflow exists", () => {
  assert.ok(existsSync(join(root, ".github/workflows/ci.yml")));
});

test(".env.example documents required variables", () => {
  const env = readFileSync(join(root, ".env.example"), "utf8");
  for (const key of ["SAFLINK_NETWORK", "SAFLINK_CONTRACT_ADDRESS", "SAFLINK_RPC_URL"]) {
    assert.match(env, new RegExp(key));
  }
});

test("network config includes saflink fees", () => {
  const mainnet = JSON.parse(readFileSync(join(root, "config/mainnet.json"), "utf8"));
  assert.equal(mainnet.saflink.nameRegistrationFeeUsaf, "50000000");
  assert.equal(mainnet.chainId, "safrochain-1");
});

test(".gitignore excludes secrets", () => {
  const gitignore = readFileSync(join(root, ".gitignore"), "utf8");
  assert.match(gitignore, /\.env/);
  assert.match(gitignore, /node_modules/);
});

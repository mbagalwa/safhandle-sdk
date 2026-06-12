#!/usr/bin/env node
/**
 * Validates required open-source documentation files exist and contain key sections.
 */
import { readFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const root = new URL("..", import.meta.url).pathname;

const requiredFiles = [
  "LICENSE",
  "README.md",
  "CONTRIBUTING.md",
  "SECURITY.md",
  "CODE_OF_CONDUCT.md",
  "CHANGELOG.md",
  ".env.example",
  ".github/pull_request_template.md",
  ".github/ISSUE_TEMPLATE/bug_report.yml",
  ".github/ISSUE_TEMPLATE/feature_request.yml",
  ".github/ISSUE_TEMPLATE/sdk_integration.yml",
  ".github/ISSUE_TEMPLATE/config.yml",
  "config/testnet.json",
  "config/mainnet.json",
  "docs/README.md",
  "docs/GETTING_STARTED.md",
  "docs/API_REFERENCE.md",
  "docs/INTEGRATION_GUIDE.md",
  "docs/WALLET_INTEGRATION.md",
  "docs/PHONE_VERIFICATION.md",
  "docs/NETWORKS.md",
  "docs/ERROR_HANDLING.md",
  "docs/ARCHITECTURE.md",
  "docs/ROADMAP.md",
  "examples/node-resolve/README.md",
  "examples/browser-wallet/README.md",
  "examples/react-hook/README.md",
];

const contentChecks = [
  {
    file: "LICENSE",
    includes: ["MIT License", "Copyright (c) 2026 Safrochain"],
  },
  {
    file: "README.md",
    includes: [
      "SAFLink SDK",
      "MIT",
      "SECURITY.md",
      "CONTRIBUTING.md",
      "GETTING_STARTED.md",
      "saflink-contract",
    ],
  },
  {
    file: "docs/API_REFERENCE.md",
    includes: ["getAddress", "registerName", "linkPhone"],
  },
  {
    file: "docs/GETTING_STARTED.md",
    includes: ["@safrochain/saflink", "50000000"],
  },
  {
    file: "SECURITY.md",
    includes: ["security@safrochain.com", "Do not open a public GitHub issue"],
  },
];

let failed = false;

for (const file of requiredFiles) {
  const path = join(root, file);
  if (!existsSync(path)) {
    console.error(`Missing required file: ${file}`);
    failed = true;
  }
}

for (const { file, includes } of contentChecks) {
  const path = join(root, file);
  if (!existsSync(path)) continue;
  const content = readFileSync(path, "utf8");
  for (const needle of includes) {
    if (!content.includes(needle)) {
      console.error(`${file}: missing expected content "${needle}"`);
      failed = true;
    }
  }
}

if (failed) {
  process.exit(1);
}

console.log("Documentation verification passed.");

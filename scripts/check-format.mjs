#!/usr/bin/env node
/**
 * Lightweight markdown formatting checks: trailing whitespace and final newline.
 */
import { readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { join, extname } from "node:path";

const root = new URL("..", import.meta.url).pathname;
const write = process.argv.includes("--write");

const markdownExtensions = new Set([".md", ".yml", ".yaml"]);

function collectMarkdownFiles(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    if (entry === "node_modules" || entry === ".git") continue;
    const path = join(dir, entry);
    const stat = statSync(path);
    if (stat.isDirectory()) {
      collectMarkdownFiles(path, files);
    } else if (markdownExtensions.has(extname(entry))) {
      files.push(path);
    }
  }
  return files;
}

let failed = false;

for (const path of collectMarkdownFiles(root)) {
  let content = readFileSync(path, "utf8");
  const original = content;

  if (content.includes("\r\n")) {
    console.error(`${path}: use LF line endings`);
    failed = true;
  }

  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const isLast = i === lines.length - 1;
    if (!isLast && /[ \t]+$/.test(line)) {
      if (write) {
        lines[i] = line.replace(/[ \t]+$/, "");
      } else {
        console.error(`${path}:${i + 1}: trailing whitespace`);
        failed = true;
      }
    }
  }

  if (write) {
    content = lines.join("\n");
    if (!content.endsWith("\n")) content += "\n";
    if (content !== original) writeFileSync(path, content);
  } else if (!original.endsWith("\n")) {
    console.error(`${path}: missing final newline`);
    failed = true;
  }
}

if (failed) {
  process.exit(1);
}

console.log(write ? "Format applied." : "Format check passed.");

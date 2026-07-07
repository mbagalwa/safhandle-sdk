// The root package.json sets "type": "module", so *.js under dist/ is ESM.
// This marker overrides that for the CJS build folder, telling Node to load
// dist/cjs/*.js as CommonJS.
import { writeFileSync } from "node:fs";

const target = new URL("../dist/cjs/package.json", import.meta.url);
writeFileSync(target, `${JSON.stringify({ type: "commonjs" }, null, 2)}\n`);
console.log("wrote dist/cjs/package.json ({ type: commonjs })");

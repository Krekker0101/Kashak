// Fallback formatter when Flutter SDK is unavailable. Normal workflow uses dart format.
import { readdirSync, readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { format } from '../.tooling/dart-formatter/package/dart_fmt_node.js';

function* files(directory) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) yield* files(path);
    else if (path.endsWith('.dart')) yield path;
  }
}
let changed = 0;
let count = 0;
for (const directory of ['lib','test','integration_test']) {
  for (const path of files(directory)) {
    const source = readFileSync(path, 'utf8');
    const output = format(source, path);
    if (source !== output) { writeFileSync(path, output); changed++; }
    count++;
  }
}
console.log(`dart_style WASM: formatted ${count} files (${changed} changed).`);

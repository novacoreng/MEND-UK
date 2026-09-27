import { existsSync, statSync } from 'node:fs';
import { resolve } from 'node:path';

const assets = [
  'assets/mend-uk-icon.png',
  'assets/mend-uk-logo.png',
  'assets/uk-flag-watermark.png',
];

const missing = assets.filter((file) => !existsSync(resolve(process.cwd(), file)));
const empty = assets.filter((file) => existsSync(resolve(process.cwd(), file)) && statSync(resolve(process.cwd(), file)).size === 0);

if (missing.length || empty.length) {
  if (missing.length) console.error(`Missing assets:\n${missing.map((f) => `- ${f}`).join('\n')}`);
  if (empty.length) console.error(`Empty assets:\n${empty.map((f) => `- ${f}`).join('\n')}`);
  process.exit(1);
}

console.log(`MEND UK assets validated (${assets.length} files).`);

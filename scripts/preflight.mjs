import { spawnSync } from 'node:child_process';

const commands = [
  ['node', ['scripts/validate-project.mjs']],
  ['node', ['scripts/check-assets.mjs']],
];

for (const [command, args] of commands) {
  const result = spawnSync(command, args, { stdio: 'inherit', shell: process.platform === 'win32' });
  if (result.status !== 0) process.exit(result.status ?? 1);
}

console.log('MEND UK preflight passed.');

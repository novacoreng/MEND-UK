import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

const root = process.cwd();
const required = [
  'package.json',
  'app.json',
  'eas.json',
  'tsconfig.json',
  'app',
  'assets',
  'lib',
  'components',
  'supabase',
];

const missing = required.filter((p) => !existsSync(resolve(root, p)));
if (missing.length) {
  console.error(`Missing required project paths:\n${missing.map((p) => `- ${p}`).join('\n')}`);
  process.exit(1);
}

const pkg = JSON.parse(readFileSync(resolve(root, 'package.json'), 'utf8'));
const app = JSON.parse(readFileSync(resolve(root, 'app.json'), 'utf8'));

const checks = [
  ['package name', pkg.name === 'mend-uk'],
  ['Expo SDK', String(pkg.dependencies?.expo ?? '').startsWith('57.')],
  ['Expo Router', Boolean(pkg.dependencies?.['expo-router'])],
  ['Stripe React Native', Boolean(pkg.dependencies?.['@stripe/stripe-react-native'])],
  ['Supabase client', Boolean(pkg.dependencies?.['@supabase/supabase-js'])],
  ['Expo icon', app.icon === './assets/mend-uk-icon.png'],
  ['Expo splash', app.splash?.image === './assets/mend-uk-logo.png'],
  ['iOS bundle identifier', app.ios?.bundleIdentifier === 'uk.mend.app'],
  ['Android package', app.android?.package === 'com.mend.uk'],
];

const failures = checks.filter(([, ok]) => !ok);
if (failures.length) {
  console.error(`Project validation failed:\n${failures.map(([name]) => `- ${name}`).join('\n')}`);
  process.exit(1);
}

console.log(`MEND UK project structure validated (${checks.length} checks).`);

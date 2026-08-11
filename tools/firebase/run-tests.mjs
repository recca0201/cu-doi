import { spawnSync } from 'node:child_process';
const args = process.argv.slice(2).filter((arg) => arg !== '--runInBand');
const patterns = args.some((arg) => arg.includes('test/rules'))
  ? ['test/rules/firestore.rules.test.ts', 'test/rules/storage.rules.test.ts']
  : ['test/firebase/verify_config.test.mjs', 'test/rules/firestore.rules.test.ts', 'test/rules/storage.rules.test.ts'];
const result = spawnSync(process.execPath, ['--import', 'tsx', '--test', ...patterns], { stdio: 'inherit', env: process.env });
process.exitCode = result.status ?? 1;

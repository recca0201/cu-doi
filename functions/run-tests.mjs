import { spawnSync } from 'node:child_process';
const requested = process.argv.slice(2).filter((arg) => !arg.startsWith('--'));
const all = ['test/profile_mutations.test.mjs','test/avatar_service.test.mjs','test/avatar_cleanup.test.mjs','test/account_deletion.test.mjs'];
const selected = requested.length ? all.filter((file) => requested.some((arg) => file.includes(arg.replace('.ts', '').replace('.mjs', '')))) : all;
const result = spawnSync(process.execPath, ['--test', ...(selected.length ? selected : all)], { stdio: 'inherit' }); process.exitCode = result.status ?? 1;

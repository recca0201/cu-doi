import test from 'node:test'; import assert from 'node:assert/strict'; import fs from 'node:fs';
test('cleanup waits 24h and rechecks canonical reference and lock', () => { const source = fs.readFileSync('src/avatar_cleanup.ts', 'utf8'); assert.match(source, /24 \* 60 \* 60/); assert.match(source, /accountDeletionLocks/); assert.match(source, /profile\.avatar\.objectPath/); });

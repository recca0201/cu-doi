import test from 'node:test';
import assert from 'node:assert/strict';
import { verify } from '../../tools/firebase/verify_config.mjs';

test('workspace has safe emulator and platform wiring', () => {
  assert.deepEqual(verify(process.cwd()), []);
});

test('release mode reports every external identity input instead of inventing it', () => {
  const errors = verify(process.cwd(), { release: true });
  assert.ok(errors.some((e) => e.includes('CU_DOI_ANDROID_APP_ID')));
  assert.ok(errors.some((e) => e.includes('CU_DOI_IOS_BUNDLE_ID')));
  assert.ok(errors.every((e) => !/private key/i.test(e)));
});

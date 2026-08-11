import fs from 'node:fs';
import test, { after, before } from 'node:test';
import { initializeTestEnvironment, assertFails, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, listAll } from 'firebase/storage';
let env: RulesTestEnvironment;
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-cu-doi', storage: { rules: fs.readFileSync('storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 } }); });
after(async () => env?.cleanup());
test('direct avatar writes and list are denied, including owner', async () => { const storage = env.authenticatedContext('alice').storage(); await assertFails(uploadBytes(ref(storage, 'avatars/alice/new.jpg'), new Uint8Array([1]))); await assertFails(listAll(ref(storage, 'avatars/alice'))); });
test('guest and cross uid writes are denied', async () => { await assertFails(uploadBytes(ref(env.unauthenticatedContext().storage(), 'avatars/alice/new.jpg'), new Uint8Array([1]))); await assertFails(uploadBytes(ref(env.authenticatedContext('bob').storage(), 'avatars/alice/new.jpg'), new Uint8Array([1]))); });

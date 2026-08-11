import fs from 'node:fs';
import test, { after, before } from 'node:test';
import { initializeTestEnvironment, assertFails, assertSucceeds, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let env: RulesTestEnvironment;
const level = { stars: 0, highScore: 0, skipped: false, losses: 0 };
const progress = { schemaVersion: 2, coins: 0, levels: Object.fromEntries(Array.from({ length: 20 }, (_, i) => [`${i + 1}`, level])) };
before(async () => { env = await initializeTestEnvironment({ projectId: 'demo-cu-doi', firestore: { rules: fs.readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 } }); });
after(async () => env?.cleanup());
test('owner may write exact progress and read it', async () => { const db = env.authenticatedContext('alice').firestore(); await assertSucceeds(setDoc(doc(db, 'users/alice'), progress)); await assertSucceeds(getDoc(doc(db, 'users/alice'))); });
test('guest, cross uid, extra field and invalid dense key are denied', async () => { await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice'), progress)); await assertFails(setDoc(doc(env.authenticatedContext('bob').firestore(), 'users/alice'), progress)); await assertFails(setDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice'), { ...progress, analytics: true })); const bad = { ...progress, levels: { ...progress.levels } }; delete bad.levels['20']; await assertFails(setDoc(doc(env.authenticatedContext('alice').firestore(), 'users/alice'), bad)); });
test('deletion lock denies owner progress recreation', async () => { await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), 'accountDeletionLocks/locked'), { jobId: 'j' })); await assertFails(setDoc(doc(env.authenticatedContext('locked').firestore(), 'users/locked'), progress)); });

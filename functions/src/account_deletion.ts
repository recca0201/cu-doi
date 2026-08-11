import { createHash, randomBytes } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { getFunctions } from 'firebase-admin/functions';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onTaskDispatched } from 'firebase-functions/v2/tasks';
import { region } from './runtime_config.js';

const hash = (value: string) => createHash('sha256').update(value).digest('hex');
const jobs = () => getFirestore().collection('accountDeletionJobs');
const queue = () => getFunctions().taskQueue(`locations/${region}/functions/accountDeletionWorker`);

export const beginAccountDeletion = onCall({ region, enforceAppCheck: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication required');
  const authTime = Number(request.auth.token.auth_time ?? 0) * 1000;
  if (Date.now() - authTime > 5 * 60 * 1000) throw new HttpsError('failed-precondition', 'Recent login required');
  const idempotencyKey = request.data?.idempotencyKey;
  if (typeof idempotencyKey !== 'string' || idempotencyKey.length < 16) throw new HttpsError('invalid-argument', 'Invalid idempotency key');
  const uid = request.auth.uid; const db = getFirestore(); const lockRef = db.doc(`accountDeletionLocks/${uid}`); const existing = await lockRef.get();
  const receipt = randomBytes(32).toString('base64url');
  if (existing.exists) {
    const job = jobs().doc(existing.get('jobId') as string); await job.set({ receiptHash: hash(receipt), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    await queue().enqueue({ jobId: job.id });
    return { receipt, requestId: existing.get('requestId') };
  }
  const jobRef = jobs().doc(); const requestId = `DEL-${randomBytes(6).toString('hex').toUpperCase()}`;
  await db.runTransaction(async (tx) => {
    if ((await tx.get(lockRef)).exists) throw new HttpsError('already-exists', 'Deletion already pending');
    tx.create(lockRef, { jobId: jobRef.id, requestId, createdAt: FieldValue.serverTimestamp() });
    tx.create(jobRef, { uid, uidHash: hash(uid), requestId, idempotencyKeyHash: hash(idempotencyKey), receiptHash: hash(receipt), phase: 'queued', checkpoint: 0, createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp() });
  });
  await queue().enqueue({ jobId: jobRef.id });
  return { receipt, requestId };
});

export const getAccountDeletionStatus = onCall({ region, enforceAppCheck: true }, async (request) => {
  const receipt = request.data?.receipt;
  if (typeof receipt !== 'string' || receipt.length < 32) throw new HttpsError('permission-denied', 'Invalid receipt');
  const snapshot = await jobs().where('receiptHash', '==', hash(receipt)).limit(1).get();
  if (snapshot.empty) throw new HttpsError('not-found', 'Unknown receipt');
  const data = snapshot.docs[0].data(); return { phase: data.phase, requestId: data.requestId, errorCode: data.errorCode ?? null };
});

export const refreshDeletionProof = onCall({ region, enforceAppCheck: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication required');
  const receipt = request.data?.receipt; if (typeof receipt !== 'string') throw new HttpsError('invalid-argument', 'Invalid receipt');
  const lock = await getFirestore().doc(`accountDeletionLocks/${request.auth.uid}`).get(); if (!lock.exists) throw new HttpsError('not-found', 'Deletion lock missing');
  const ref = jobs().doc(lock.get('jobId') as string); const job = await ref.get(); if (job.get('receiptHash') !== hash(receipt)) throw new HttpsError('permission-denied', 'Receipt mismatch');
  await ref.update({ phase: 'queued', errorCode: FieldValue.delete(), proofRefreshedAt: FieldValue.serverTimestamp() }); return { resumed: true };
});

export const accountDeletionWorker = onTaskDispatched({ region, retryConfig: { maxAttempts: 20, minBackoffSeconds: 10, maxBackoffSeconds: 3600 }, rateLimits: { maxConcurrentDispatches: 10 } }, async (request) => {
  const jobId = request.data?.jobId; if (typeof jobId !== 'string') throw new Error('Missing jobId');
  const ref = jobs().doc(jobId); const snapshot = await ref.get(); if (!snapshot.exists) return; const data = snapshot.data()!; const uid = data.uid as string; let checkpoint = Number(data.checkpoint ?? 0);
  await ref.update({ phase: 'deleting', updatedAt: FieldValue.serverTimestamp() });
  if (checkpoint < 1) { const [files] = await getStorage().bucket().getFiles({ prefix: `avatars/${uid}/` }); await Promise.all(files.map((file) => file.delete({ ignoreNotFound: true }))); checkpoint = 1; await ref.update({ checkpoint }); }
  if (checkpoint < 2) { await getFirestore().recursiveDelete(getFirestore().doc(`users/${uid}`)); checkpoint = 2; await ref.update({ checkpoint }); }
  // Provider grant revocation hooks are intentionally deployment integrations; no token is stored in profile documents.
  if (checkpoint < 3) { checkpoint = 3; await ref.update({ checkpoint, providersRevokedAt: FieldValue.serverTimestamp() }); }
  if (checkpoint < 4) { await getAuth().revokeRefreshTokens(uid); await getAuth().updateUser(uid, { disabled: true }); checkpoint = 4; await ref.update({ checkpoint }); }
  if (checkpoint < 5) { await getAuth().deleteUser(uid); checkpoint = 5; await ref.update({ checkpoint, phase: 'finalSweep', sweepAfter: Timestamp.fromMillis(Date.now() + 70 * 60 * 1000) }); await queue().enqueue({ jobId }, { scheduleDelaySeconds: 70 * 60 }); return; }
  if (Date.now() < (data.sweepAfter?.toMillis?.() ?? 0)) return;
  const [files] = await getStorage().bucket().getFiles({ prefix: `avatars/${uid}/` }); await Promise.all(files.map((file) => file.delete({ ignoreNotFound: true })));
  await getFirestore().recursiveDelete(getFirestore().doc(`users/${uid}`)); await getFirestore().doc(`accountDeletionLocks/${uid}`).delete();
  await ref.update({ phase: 'completed', completedAt: FieldValue.serverTimestamp(), terminalExpiresAt: Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000), uid: FieldValue.delete() });
});

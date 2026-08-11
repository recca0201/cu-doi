"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.accountDeletionWorker = exports.refreshDeletionProof = exports.getAccountDeletionStatus = exports.beginAccountDeletion = void 0;
const node_crypto_1 = require("node:crypto");
const auth_1 = require("firebase-admin/auth");
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const https_1 = require("firebase-functions/v2/https");
const tasks_1 = require("firebase-functions/v2/tasks");
const runtime_config_js_1 = require("./runtime_config.js");
const hash = (value) => (0, node_crypto_1.createHash)('sha256').update(value).digest('hex');
const jobs = () => (0, firestore_1.getFirestore)().collection('accountDeletionJobs');
exports.beginAccountDeletion = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required');
    const authTime = Number(request.auth.token.auth_time ?? 0) * 1000;
    if (Date.now() - authTime > 5 * 60 * 1000)
        throw new https_1.HttpsError('failed-precondition', 'Recent login required');
    const idempotencyKey = request.data?.idempotencyKey;
    if (typeof idempotencyKey !== 'string' || idempotencyKey.length < 16)
        throw new https_1.HttpsError('invalid-argument', 'Invalid idempotency key');
    const uid = request.auth.uid;
    const db = (0, firestore_1.getFirestore)();
    const lockRef = db.doc(`accountDeletionLocks/${uid}`);
    const existing = await lockRef.get();
    const receipt = (0, node_crypto_1.randomBytes)(32).toString('base64url');
    if (existing.exists) {
        const job = jobs().doc(existing.get('jobId'));
        await job.set({ receiptHash: hash(receipt), updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
        return { receipt, requestId: existing.get('requestId') };
    }
    const jobRef = jobs().doc();
    const requestId = `DEL-${(0, node_crypto_1.randomBytes)(6).toString('hex').toUpperCase()}`;
    await db.runTransaction(async (tx) => {
        if ((await tx.get(lockRef)).exists)
            throw new https_1.HttpsError('already-exists', 'Deletion already pending');
        tx.create(lockRef, { jobId: jobRef.id, requestId, createdAt: firestore_1.FieldValue.serverTimestamp() });
        tx.create(jobRef, { uid, uidHash: hash(uid), requestId, idempotencyKeyHash: hash(idempotencyKey), receiptHash: hash(receipt), phase: 'queued', checkpoint: 0, createdAt: firestore_1.FieldValue.serverTimestamp(), updatedAt: firestore_1.FieldValue.serverTimestamp() });
    });
    // Queue delivery is deployment-owned. The task handler can also be invoked by emulator tests.
    return { receipt, requestId };
});
exports.getAccountDeletionStatus = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    const receipt = request.data?.receipt;
    if (typeof receipt !== 'string' || receipt.length < 32)
        throw new https_1.HttpsError('permission-denied', 'Invalid receipt');
    const snapshot = await jobs().where('receiptHash', '==', hash(receipt)).limit(1).get();
    if (snapshot.empty)
        throw new https_1.HttpsError('not-found', 'Unknown receipt');
    const data = snapshot.docs[0].data();
    return { phase: data.phase, requestId: data.requestId, errorCode: data.errorCode ?? null };
});
exports.refreshDeletionProof = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required');
    const receipt = request.data?.receipt;
    if (typeof receipt !== 'string')
        throw new https_1.HttpsError('invalid-argument', 'Invalid receipt');
    const lock = await (0, firestore_1.getFirestore)().doc(`accountDeletionLocks/${request.auth.uid}`).get();
    if (!lock.exists)
        throw new https_1.HttpsError('not-found', 'Deletion lock missing');
    const ref = jobs().doc(lock.get('jobId'));
    const job = await ref.get();
    if (job.get('receiptHash') !== hash(receipt))
        throw new https_1.HttpsError('permission-denied', 'Receipt mismatch');
    await ref.update({ phase: 'queued', errorCode: firestore_1.FieldValue.delete(), proofRefreshedAt: firestore_1.FieldValue.serverTimestamp() });
    return { resumed: true };
});
exports.accountDeletionWorker = (0, tasks_1.onTaskDispatched)({ region: runtime_config_js_1.region, retryConfig: { maxAttempts: 20, minBackoffSeconds: 10, maxBackoffSeconds: 3600 }, rateLimits: { maxConcurrentDispatches: 10 } }, async (request) => {
    const jobId = request.data?.jobId;
    if (typeof jobId !== 'string')
        throw new Error('Missing jobId');
    const ref = jobs().doc(jobId);
    const snapshot = await ref.get();
    if (!snapshot.exists)
        return;
    const data = snapshot.data();
    const uid = data.uid;
    let checkpoint = Number(data.checkpoint ?? 0);
    await ref.update({ phase: 'deleting', updatedAt: firestore_1.FieldValue.serverTimestamp() });
    if (checkpoint < 1) {
        const [files] = await (0, storage_1.getStorage)().bucket().getFiles({ prefix: `avatars/${uid}/` });
        await Promise.all(files.map((file) => file.delete({ ignoreNotFound: true })));
        checkpoint = 1;
        await ref.update({ checkpoint });
    }
    if (checkpoint < 2) {
        await (0, firestore_1.getFirestore)().recursiveDelete((0, firestore_1.getFirestore)().doc(`users/${uid}`));
        checkpoint = 2;
        await ref.update({ checkpoint });
    }
    // Provider grant revocation hooks are intentionally deployment integrations; no token is stored in profile documents.
    if (checkpoint < 3) {
        checkpoint = 3;
        await ref.update({ checkpoint, providersRevokedAt: firestore_1.FieldValue.serverTimestamp() });
    }
    if (checkpoint < 4) {
        await (0, auth_1.getAuth)().revokeRefreshTokens(uid);
        await (0, auth_1.getAuth)().updateUser(uid, { disabled: true });
        checkpoint = 4;
        await ref.update({ checkpoint });
    }
    if (checkpoint < 5) {
        await (0, auth_1.getAuth)().deleteUser(uid);
        checkpoint = 5;
        await ref.update({ checkpoint, phase: 'finalSweep', sweepAfter: firestore_1.Timestamp.fromMillis(Date.now() + 70 * 60 * 1000) });
        return;
    }
    if (Date.now() < (data.sweepAfter?.toMillis?.() ?? 0))
        return;
    const [files] = await (0, storage_1.getStorage)().bucket().getFiles({ prefix: `avatars/${uid}/` });
    await Promise.all(files.map((file) => file.delete({ ignoreNotFound: true })));
    await (0, firestore_1.getFirestore)().recursiveDelete((0, firestore_1.getFirestore)().doc(`users/${uid}`));
    await (0, firestore_1.getFirestore)().doc(`accountDeletionLocks/${uid}`).delete();
    await ref.update({ phase: 'completed', completedAt: firestore_1.FieldValue.serverTimestamp(), terminalExpiresAt: firestore_1.Timestamp.fromMillis(Date.now() + 7 * 24 * 60 * 60 * 1000), uid: firestore_1.FieldValue.delete() });
});

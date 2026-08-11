"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.commitProfileMutation = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const runtime_config_js_1 = require("./runtime_config.js");
exports.commitProfileMutation = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required');
    const { mutationId, displayName } = request.data ?? {};
    if (typeof mutationId !== 'string' || !/^[A-Za-z0-9_-]{16,64}$/.test(mutationId))
        throw new https_1.HttpsError('invalid-argument', 'Invalid mutation');
    if (typeof displayName !== 'string' || !displayName.trim() || [...displayName.trim()].length > 40)
        throw new https_1.HttpsError('invalid-argument', 'Invalid display name');
    const uid = request.auth.uid;
    const db = (0, firestore_1.getFirestore)();
    const user = db.doc(`users/${uid}`);
    const mutation = user.collection('profileMutations').doc(mutationId);
    const committedAt = firestore_1.Timestamp.now();
    return db.runTransaction(async (tx) => { const prior = await tx.get(mutation); if (prior.exists)
        return prior.data(); const result = { mutationId, serverCommittedAt: committedAt, displayName: displayName.trim().replace(/\s+/g, ' ') }; tx.set(mutation, result); tx.set(user, { profile: { customDisplayName: result.displayName }, profileOrder: { serverCommittedAt: committedAt, mutationId }, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true }); return result; });
});

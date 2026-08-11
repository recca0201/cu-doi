"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.selectPresetAvatar = exports.uploadAvatar = void 0;
const node_crypto_1 = require("node:crypto");
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const https_1 = require("firebase-functions/v2/https");
const runtime_config_js_1 = require("./runtime_config.js");
function requireUser(request) {
    if (!request.auth)
        throw new https_1.HttpsError('unauthenticated', 'Authentication required');
    return request.auth.uid;
}
exports.uploadAvatar = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    const uid = requireUser(request);
    const { bytesBase64, contentType, mutationId, sha256 } = request.data ?? {};
    if (typeof mutationId !== 'string' || !/^[A-Za-z0-9_-]{16,64}$/.test(mutationId))
        throw new https_1.HttpsError('invalid-argument', 'Invalid mutation');
    if (!['image/jpeg', 'image/webp'].includes(contentType) || typeof bytesBase64 !== 'string')
        throw new https_1.HttpsError('invalid-argument', 'Invalid image');
    const bytes = Buffer.from(bytesBase64, 'base64');
    if (!bytes.length || bytes.length > runtime_config_js_1.avatarLimitBytes || (0, node_crypto_1.createHash)('sha256').update(bytes).digest('hex') !== sha256)
        throw new https_1.HttpsError('invalid-argument', 'Invalid image bounds/hash');
    const db = (0, firestore_1.getFirestore)();
    if ((await db.doc(`accountDeletionLocks/${uid}`).get()).exists)
        throw new https_1.HttpsError('failed-precondition', 'Deletion locked');
    const extension = contentType === 'image/webp' ? 'webp' : 'jpg';
    const objectId = `${mutationId}-${(0, node_crypto_1.randomBytes)(8).toString('hex')}.${extension}`;
    const path = `avatars/${uid}/${objectId}`;
    const file = (0, storage_1.getStorage)().bucket().file(path);
    await file.save(bytes, { resumable: false, validation: 'md5', metadata: { contentType, cacheControl: 'private,max-age=3600', metadata: { ownerUid: uid, mutationId, sha256 } } });
    const userRef = db.doc(`users/${uid}`);
    let previous;
    await db.runTransaction(async (tx) => {
        const [user, lock] = await Promise.all([tx.get(userRef), tx.get(db.doc(`accountDeletionLocks/${uid}`))]);
        if (lock.exists)
            throw new https_1.HttpsError('failed-precondition', 'Deletion locked');
        previous = user.get('profile.avatar.objectPath');
        tx.set(userRef, { profile: { avatar: { kind: 'custom', objectPath: path, contentType, sha256 } }, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    });
    if (previous && previous !== path && previous.startsWith(`avatars/${uid}/`))
        await (0, storage_1.getStorage)().bucket().file(previous).delete({ ignoreNotFound: true });
    return { objectPath: path, contentType, sha256 };
});
exports.selectPresetAvatar = (0, https_1.onCall)({ region: runtime_config_js_1.region, enforceAppCheck: true }, async (request) => {
    const uid = requireUser(request);
    const presetId = request.data?.presetId;
    const allowed = new Set(['pangolin-gold', 'pangolin-blue', 'pangolin-purple', 'galaxy-gold', 'galaxy-blue', 'galaxy-purple']);
    if (typeof presetId !== 'string' || !allowed.has(presetId))
        throw new https_1.HttpsError('invalid-argument', 'Invalid preset');
    const db = (0, firestore_1.getFirestore)();
    const ref = db.doc(`users/${uid}`);
    const snapshot = await ref.get();
    const previous = snapshot.get('profile.avatar.objectPath');
    await ref.set({ profile: { avatar: { kind: 'preset', presetId } }, updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
    if (previous?.startsWith(`avatars/${uid}/`))
        await (0, storage_1.getStorage)().bucket().file(previous).delete({ ignoreNotFound: true });
    return { kind: 'preset', presetId };
});

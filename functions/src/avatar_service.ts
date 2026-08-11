import { createHash, randomBytes } from 'node:crypto';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { avatarLimitBytes, region } from './runtime_config.js';

function requireUser(request: { auth?: { uid: string } }): string {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication required');
  return request.auth.uid;
}

export const uploadAvatar = onCall({ region, enforceAppCheck: true }, async (request) => {
  const uid = requireUser(request);
  const { bytesBase64, contentType, mutationId, sha256 } = request.data ?? {};
  if (typeof mutationId !== 'string' || !/^[A-Za-z0-9_-]{16,64}$/.test(mutationId)) throw new HttpsError('invalid-argument', 'Invalid mutation');
  if (!['image/jpeg', 'image/webp'].includes(contentType) || typeof bytesBase64 !== 'string') throw new HttpsError('invalid-argument', 'Invalid image');
  const bytes = Buffer.from(bytesBase64, 'base64');
  if (!bytes.length || bytes.length > avatarLimitBytes || createHash('sha256').update(bytes).digest('hex') !== sha256) throw new HttpsError('invalid-argument', 'Invalid image bounds/hash');
  const db = getFirestore();
  if ((await db.doc(`accountDeletionLocks/${uid}`).get()).exists) throw new HttpsError('failed-precondition', 'Deletion locked');
  const extension = contentType === 'image/webp' ? 'webp' : 'jpg';
  const objectId = `${mutationId}-${randomBytes(8).toString('hex')}.${extension}`;
  const path = `avatars/${uid}/${objectId}`;
  const file = getStorage().bucket().file(path);
  await file.save(bytes, { resumable: false, validation: 'md5', metadata: { contentType, cacheControl: 'private,max-age=3600', metadata: { ownerUid: uid, mutationId, sha256 } } });
  const userRef = db.doc(`users/${uid}`);
  let previous: string | undefined;
  await db.runTransaction(async (tx) => {
    const [user, lock] = await Promise.all([tx.get(userRef), tx.get(db.doc(`accountDeletionLocks/${uid}`))]);
    if (lock.exists) throw new HttpsError('failed-precondition', 'Deletion locked');
    previous = user.get('profile.avatar.objectPath') as string | undefined;
    tx.set(userRef, { profile: { avatar: { kind: 'custom', objectPath: path, contentType, sha256 } }, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  });
  if (previous && previous !== path && previous.startsWith(`avatars/${uid}/`)) await getStorage().bucket().file(previous).delete({ ignoreNotFound: true });
  return { objectPath: path, contentType, sha256 };
});

export const selectPresetAvatar = onCall({ region, enforceAppCheck: true }, async (request) => {
  const uid = requireUser(request); const presetId = request.data?.presetId;
  const allowed = new Set(['pangolin-gold','pangolin-blue','pangolin-purple','galaxy-gold','galaxy-blue','galaxy-purple']);
  if (typeof presetId !== 'string' || !allowed.has(presetId)) throw new HttpsError('invalid-argument', 'Invalid preset');
  const db = getFirestore(); const ref = db.doc(`users/${uid}`); const snapshot = await ref.get(); const previous = snapshot.get('profile.avatar.objectPath') as string | undefined;
  await ref.set({ profile: { avatar: { kind: 'preset', presetId } }, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  if (previous?.startsWith(`avatars/${uid}/`)) await getStorage().bucket().file(previous).delete({ ignoreNotFound: true });
  return { kind: 'preset', presetId };
});

import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { region } from './runtime_config.js';

export const commitProfileMutation = onCall({ region, enforceAppCheck: true }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Authentication required');
  const { mutationId, displayName } = request.data ?? {};
  if (typeof mutationId !== 'string' || !/^[A-Za-z0-9_-]{16,64}$/.test(mutationId)) throw new HttpsError('invalid-argument', 'Invalid mutation');
  if (typeof displayName !== 'string' || !displayName.trim() || [...displayName.trim()].length > 40) throw new HttpsError('invalid-argument', 'Invalid display name');
  const uid = request.auth.uid; const db = getFirestore(); const user = db.doc(`users/${uid}`); const mutation = user.collection('profileMutations').doc(mutationId); const committedAt = Timestamp.now();
  return db.runTransaction(async (tx) => { const prior = await tx.get(mutation); if (prior.exists) return prior.data(); const result = { mutationId, serverCommittedAt: committedAt, displayName: displayName.trim().replace(/\s+/g, ' ') }; tx.set(mutation, result); tx.set(user, { profile: { customDisplayName: result.displayName }, profileOrder: { serverCommittedAt: committedAt, mutationId }, updatedAt: FieldValue.serverTimestamp() }, { merge: true }); return result; });
});

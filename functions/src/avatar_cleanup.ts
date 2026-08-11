import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { region } from './runtime_config.js';

export const avatarCleanup = onSchedule({ schedule: 'every day 03:00', region }, async () => {
  const [files] = await getStorage().bucket().getFiles({ prefix: 'avatars/' }); const db = getFirestore(); const cutoff = Date.now() - 24 * 60 * 60 * 1000;
  for (const file of files) {
    const parts = file.name.split('/'); if (parts.length !== 3) continue;
    const [metadata] = await file.getMetadata(); if (Date.parse(metadata.timeCreated ?? '') > cutoff) continue;
    const uid = parts[1]; const [user, lock] = await Promise.all([db.doc(`users/${uid}`).get(), db.doc(`accountDeletionLocks/${uid}`).get()]);
    if (lock.exists || user.get('profile.avatar.objectPath') === file.name) continue;
    await file.delete({ ignoreNotFound: true });
  }
});

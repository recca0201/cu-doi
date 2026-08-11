"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.avatarCleanup = void 0;
const firestore_1 = require("firebase-admin/firestore");
const storage_1 = require("firebase-admin/storage");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const runtime_config_js_1 = require("./runtime_config.js");
exports.avatarCleanup = (0, scheduler_1.onSchedule)({ schedule: 'every day 03:00', region: runtime_config_js_1.region }, async () => {
    const [files] = await (0, storage_1.getStorage)().bucket().getFiles({ prefix: 'avatars/' });
    const db = (0, firestore_1.getFirestore)();
    const cutoff = Date.now() - 24 * 60 * 60 * 1000;
    for (const file of files) {
        const parts = file.name.split('/');
        if (parts.length !== 3)
            continue;
        const [metadata] = await file.getMetadata();
        if (Date.parse(metadata.timeCreated ?? '') > cutoff)
            continue;
        const uid = parts[1];
        const [user, lock] = await Promise.all([db.doc(`users/${uid}`).get(), db.doc(`accountDeletionLocks/${uid}`).get()]);
        if (lock.exists || user.get('profile.avatar.objectPath') === file.name)
            continue;
        await file.delete({ ignoreNotFound: true });
    }
});

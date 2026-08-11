import { initializeApp } from 'firebase-admin/app';
initializeApp();
export { commitProfileMutation } from './profile_mutations.js';
export { uploadAvatar, selectPresetAvatar } from './avatar_service.js';
export { avatarCleanup } from './avatar_cleanup.js';
export { beginAccountDeletion, getAccountDeletionStatus, refreshDeletionProof, accountDeletionWorker } from './account_deletion.js';

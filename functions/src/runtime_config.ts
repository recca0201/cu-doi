export const region = process.env.FUNCTIONS_REGION ?? 'asia-southeast1';
export const deletionQueue = process.env.DELETION_QUEUE ?? 'account-deletion';
export const avatarLimitBytes = 2 * 1024 * 1024;

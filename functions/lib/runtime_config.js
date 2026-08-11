"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.avatarLimitBytes = exports.deletionQueue = exports.region = void 0;
exports.region = process.env.FUNCTIONS_REGION ?? 'asia-southeast1';
exports.deletionQueue = process.env.DELETION_QUEUE ?? 'account-deletion';
exports.avatarLimitBytes = 2 * 1024 * 1024;

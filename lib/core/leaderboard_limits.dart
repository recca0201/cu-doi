/// Shared Dart-side resource limits for the custom platform leaderboards.
///
/// Native bridges mirror the channel and payload values. Keeping the values
/// here gives their contract tests one source of truth without introducing a
/// platform dependency into the domain or simulation layers.
const Duration kLeaderboardReadTimeout = Duration(seconds: 10);
const Duration kLeaderboardSubmitTimeout = Duration(seconds: 8);
const Duration kLeaderboardAvatarTimeout = Duration(seconds: 5);

const int kLeaderboardPageSize = 25;
const int kMaxLeaderboardRows = 100;

const int kMaxAvatarBytes = 256 * 1024;
const int kMaxConcurrentAvatarRequests = 4;
const int kMaxPendingAvatarRequests = 32;
const int kMaxAvatarCacheEntries = 32;
const int kMaxAvatarCacheBytes = 8 * 1024 * 1024;

const int kMaxLeaderboardSnapshotBytes = 128 * 1024;
const int kMaxLeaderboardSnapshotsPerIdentity = 40;

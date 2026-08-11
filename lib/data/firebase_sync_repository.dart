import '../domain/player_progress.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_player_store.dart';

const int kCloudSchemaVersion = 2;

class ProgressCloudCodec {
  static Map<String, Object> encode(
    PlayerProgress progress,
  ) => <String, Object>{
    'schemaVersion': kCloudSchemaVersion,
    'coins': progress.coins.clamp(0, 0x7fffffff),
    'levels': <String, Object>{
      for (var id = 1; id <= 20; id++)
        '$id': <String, Object>{
          'stars': progress.starsFor(id).clamp(0, 3),
          'highScore': progress.highScoreFor(id).clamp(0, 0x7fffffff),
          'skipped': progress.isCompleted(id) ? false : progress.isSkipped(id),
          'losses': progress.lossesFor(id).clamp(0, 0x7fffffff),
        },
    },
  };

  static PlayerProgress decode(Object? value) {
    if (value is! Map ||
        value['schemaVersion'] != kCloudSchemaVersion ||
        value['coins'] is! int ||
        value['levels'] is! Map) {
      throw const FormatException('Unsupported progress schema');
    }
    final levels = value['levels'] as Map;
    if (levels.length != 20 ||
        !List.generate(20, (i) => '${i + 1}').every(levels.containsKey)) {
      throw const FormatException('Progress must contain levels 1..20');
    }
    final Map<int, LevelResult> results = <int, LevelResult>{};
    for (var id = 1; id <= 20; id++) {
      final raw = levels['$id'];
      if (raw is! Map ||
          raw.keys.any(
            (k) =>
                !const {'stars', 'highScore', 'skipped', 'losses'}.contains(k),
          )) {
        throw const FormatException('Invalid level');
      }
      final stars = raw['stars'];
      final score = raw['highScore'];
      final skipped = raw['skipped'];
      final losses = raw['losses'];
      if (stars is! int ||
          stars < 0 ||
          stars > 3 ||
          score is! int ||
          score < 0 ||
          score > 0x7fffffff ||
          skipped is! bool ||
          losses is! int ||
          losses < 0 ||
          losses > 0x7fffffff) {
        throw const FormatException('Invalid level bounds');
      }
      if (stars > 0 || score > 0 || skipped || losses > 0) {
        results[id] = LevelResult(
          stars: stars,
          highScore: score,
          skipped: stars == 0 && skipped,
          losses: losses,
        );
      }
    }
    final coins = value['coins'] as int;
    if (coins < 0 || coins > 0x7fffffff) {
      throw const FormatException('Invalid coins');
    }
    return PlayerProgress(results: results, coins: coins);
  }
}

abstract class FirebaseSyncRepository {
  Future<PlayerProgress> reconcile(String uid, PlayerProgress local);
  Future<void> commitProfileMutation(String uid, Map<String, Object?> mutation);
}

class FirestoreSyncRepository implements FirebaseSyncRepository {
  FirestoreSyncRepository(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<PlayerProgress> reconcile(String uid, PlayerProgress local) async {
    final ref = firestore.doc('users/$uid');
    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      PlayerProgress remote = const PlayerProgress();
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          remote = ProgressCloudCodec.decode(<String, Object?>{
            'schemaVersion': data['schemaVersion'],
            'coins': data['coins'],
            'levels': data['levels'],
          });
        }
      }
      final merged = PlayerProgress.merge(local, remote);
      transaction.set(ref, <String, Object>{
        ...ProgressCloudCodec.encode(merged),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return merged;
    });
  }

  @override
  Future<void> commitProfileMutation(
    String uid,
    Map<String, Object?> mutation,
  ) async {
    throw UnsupportedError('Profile mutations are callable-only');
  }
}

class SyncQueueState {
  const SyncQueueState({
    this.progressPending = false,
    this.mutations = const [],
    this.retryCount = 0,
    this.nextAttemptAtMs,
  });
  final bool progressPending;
  final List<PendingMutation> mutations;
  final int retryCount;
  final int? nextAttemptAtMs;
  Duration get backoff {
    final seconds = retryCount <= 0 ? 1 : (1 << retryCount.clamp(0, 8));
    return Duration(seconds: seconds.clamp(1, 300));
  }
}

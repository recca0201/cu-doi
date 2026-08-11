import 'dart:convert';
import 'dart:developer' as dev;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/player_profile.dart';
import '../domain/player_progress.dart';

enum OwnerKind { guest, account }

class OwnerKey {
  const OwnerKey._(this.kind, this.value);
  const OwnerKey.guest([String provenance = 'unclaimed'])
    : this._(OwnerKind.guest, provenance);
  factory OwnerKey.account(String uid) => OwnerKey._(
    OwnerKind.account,
    sha256.convert(utf8.encode(uid)).toString(),
  );
  factory OwnerKey.uidDerivedGuest(String uid) =>
      OwnerKey._(OwnerKind.guest, 'from_${sha256.convert(utf8.encode(uid))}');
  final OwnerKind kind;
  final String value;
  String get storageId => '${kind.name}_$value';
}

class OwnerLease {
  const OwnerLease(
    this.owner,
    this.epoch, [
    this.deletionEpoch = 0,
    this._validator,
  ]);
  final OwnerKey owner;
  final int epoch;
  final int deletionEpoch;
  final bool Function()? _validator;
  bool isCurrent() => _validator?.call() ?? true;
}

class PendingMutation {
  const PendingMutation({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAtMs,
  });
  final String id;
  final String kind;
  final Map<String, Object?> payload;
  final int createdAtMs;
  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'payload': payload,
    'createdAtMs': createdAtMs,
  };
  factory PendingMutation.fromJson(Map<String, dynamic> j) => PendingMutation(
    id: j['id'] as String,
    kind: j['kind'] as String,
    payload: Map<String, Object?>.from(j['payload'] as Map),
    createdAtMs: j['createdAtMs'] as int,
  );
}

class PlayerEnvelope {
  const PlayerEnvelope({
    this.schemaVersion = 2,
    this.progress = const PlayerProgress(),
    this.profile = const PlayerProfile(),
    this.pending = const [],
    this.deletionPending = false,
    this.signInReminderDismissed = false,
    this.revision = 0,
    this.ownerEpoch = 0,
    this.deletionEpoch = 0,
  });
  final int schemaVersion;
  final PlayerProgress progress;
  final PlayerProfile profile;
  final List<PendingMutation> pending;
  final bool deletionPending;
  final bool signInReminderDismissed;
  final int revision;
  final int ownerEpoch;
  final int deletionEpoch;
  PlayerEnvelope copyWith({
    PlayerProgress? progress,
    PlayerProfile? profile,
    List<PendingMutation>? pending,
    bool? deletionPending,
    bool? signInReminderDismissed,
    int? revision,
    int? ownerEpoch,
    int? deletionEpoch,
  }) => PlayerEnvelope(
    progress: progress ?? this.progress,
    profile: profile ?? this.profile,
    pending: pending ?? this.pending,
    deletionPending: deletionPending ?? this.deletionPending,
    signInReminderDismissed:
        signInReminderDismissed ?? this.signInReminderDismissed,
    revision: revision ?? this.revision,
    ownerEpoch: ownerEpoch ?? this.ownerEpoch,
    deletionEpoch: deletionEpoch ?? this.deletionEpoch,
  );
  Map<String, Object?> toJson() => {
    'schemaVersion': 2,
    'progress': progress.toJson(),
    'profile': profile.toJson(),
    'pending': pending.map((e) => e.toJson()).toList(),
    'deletionPending': deletionPending,
    'signInReminderDismissed': signInReminderDismissed,
    'revision': revision,
    'ownerEpoch': ownerEpoch,
    'deletionEpoch': deletionEpoch,
  };
  factory PlayerEnvelope.fromJson(Map<String, dynamic> j) {
    if (j['schemaVersion'] != 2) {
      throw const FormatException('Unsupported envelope');
    }
    return PlayerEnvelope(
      progress: PlayerProgress.fromJson(
        Map<String, dynamic>.from(j['progress'] as Map? ?? const {}),
      ),
      profile: PlayerProfile.fromJson(
        Map<String, dynamic>.from(j['profile'] as Map? ?? const {}),
      ),
      pending: (j['pending'] as List? ?? const [])
          .map(
            (e) =>
                PendingMutation.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      deletionPending: j['deletionPending'] == true,
      signInReminderDismissed: j['signInReminderDismissed'] == true,
      revision: j['revision'] as int? ?? 0,
      ownerEpoch: j['ownerEpoch'] as int? ?? 0,
      deletionEpoch: j['deletionEpoch'] as int? ?? 0,
    );
  }
}

class LocalPlayerStore {
  LocalPlayerStore(this._prefs);
  final SharedPreferences _prefs;
  final Map<String, Future<void>> _tails = {};
  final Map<String, int> _ownerEpochs = {};
  final Map<String, int> _deletionEpochs = {};
  String _prefix(OwnerKey owner) => 'player_v2_${owner.storageId}';

  Future<PlayerEnvelope> load(OwnerKey owner) async {
    final prefix = _prefix(owner);
    final active = _prefs.getInt('${prefix}_active') ?? 0;
    for (final generation in <int>[active, 1 - active]) {
      final raw = _prefs.getString('${prefix}_$generation');
      if (raw == null) continue;
      try {
        return PlayerEnvelope.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        dev.log(
          'quarantined corrupt player cache',
          name: 'data.player_store',
          error: e,
        );
      }
    }
    if (owner.kind == OwnerKind.guest) {
      final legacy = _prefs.getString('progress_v1');
      if (legacy != null) {
        try {
          final migrated = PlayerEnvelope(
            progress: PlayerProgress.fromJson(
              jsonDecode(legacy) as Map<String, dynamic>,
            ),
          );
          await save(owner, migrated);
          return migrated;
        } catch (_) {}
      }
    }
    return const PlayerEnvelope();
  }

  Future<bool> save(OwnerKey owner, PlayerEnvelope envelope) async {
    final key = owner.storageId;
    var result = false;
    final previous = _tails[key] ?? Future<void>.value();
    final next = previous.then((_) async {
      result = await _commit(owner, envelope);
    });
    _tails[key] = next;
    await next;
    if (identical(_tails[key], next)) _tails.remove(key);
    return result;
  }

  OwnerLease lease(OwnerKey owner) {
    final ownerEpoch = _ownerEpochs[owner.storageId] ?? 0;
    final deletionEpoch = _deletionEpochs[owner.storageId] ?? 0;
    return OwnerLease(
      owner,
      ownerEpoch,
      deletionEpoch,
      () =>
          (_ownerEpochs[owner.storageId] ?? 0) == ownerEpoch &&
          (_deletionEpochs[owner.storageId] ?? 0) == deletionEpoch,
    );
  }

  void invalidate(OwnerKey owner, {bool deletion = false}) {
    _ownerEpochs[owner.storageId] = (_ownerEpochs[owner.storageId] ?? 0) + 1;
    if (deletion) {
      _deletionEpochs[owner.storageId] =
          (_deletionEpochs[owner.storageId] ?? 0) + 1;
    }
  }

  Future<bool> claimGuest(OwnerKey guest, String uid) async {
    final account = OwnerKey.account(uid);
    final current = await load(account);
    if (current.revision > 0) return true;
    return save(account, await load(guest));
  }

  Future<OwnerKey> createGuestCopyFromUid(String uid) async {
    final guest = OwnerKey.uidDerivedGuest(uid);
    final account = await load(OwnerKey.account(uid));
    if (!await save(guest, account.copyWith(deletionPending: false))) {
      throw StateError('Could not create guest copy');
    }
    return guest;
  }

  Future<bool> _commit(OwnerKey owner, PlayerEnvelope envelope) async {
    final prefix = _prefix(owner);
    final active = _prefs.getInt('${prefix}_active') ?? 0;
    final next = 1 - active;
    final value = jsonEncode(
      envelope.copyWith(revision: envelope.revision + 1).toJson(),
    );
    if (!await _prefs.setString('${prefix}_$next', value)) return false;
    if (_prefs.getString('${prefix}_$next') != value) return false;
    return _prefs.setInt('${prefix}_active', next);
  }
}

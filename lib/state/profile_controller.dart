import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local_player_store.dart';
import '../domain/player_profile.dart';

class ProfileState {
  const ProfileState({
    this.profile = const PlayerProfile(),
    this.restoring = true,
    this.saving = false,
    this.draft,
    this.error,
  });
  final PlayerProfile profile;
  final bool restoring;
  final bool saving;
  final String? draft;
  final String? error;
  ProfileState copyWith({
    PlayerProfile? profile,
    bool? restoring,
    bool? saving,
    String? draft,
    String? error,
    bool clearError = false,
  }) => ProfileState(
    profile: profile ?? this.profile,
    restoring: restoring ?? this.restoring,
    saving: saving ?? this.saving,
    draft: draft ?? this.draft,
    error: clearError ? null : error ?? this.error,
  );
}

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this.store, this.owner) : super(const ProfileState()) {
    _ready = restore();
  }
  final LocalPlayerStore store;
  final OwnerKey owner;
  late final Future<void> _ready;
  Future<void> get ready => _ready;

  Future<void> restore() async {
    final envelope = await store.load(owner);
    state = ProfileState(profile: envelope.profile, restoring: false);
  }

  void beginNameEdit() => state = state.copyWith(
    draft: state.profile.customDisplayName ?? '',
    clearError: true,
  );
  void updateDraft(String value) =>
      state = state.copyWith(draft: value, clearError: true);
  void cancelEdit() =>
      state = ProfileState(profile: state.profile, restoring: false);
  Future<bool> saveName([String? value]) async {
    await ready;
    final draft = value ?? state.draft ?? '';
    final error = PlayerProfile.validateDisplayName(draft);
    if (error != null) {
      state = state.copyWith(error: error);
      return false;
    }
    final normalized = PlayerProfile.normalizeDisplayName(draft);
    final old = state;
    state = state.copyWith(saving: true, clearError: true);
    final envelope = await store.load(owner);
    final mutation = PendingMutation(
      id: _id(),
      kind: 'displayName',
      payload: {'value': normalized},
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final nextProfile = envelope.profile.copyWith(
      customDisplayName: normalized,
    );
    if (!await store.save(
      owner,
      envelope.copyWith(
        profile: nextProfile,
        pending: [...envelope.pending, mutation],
      ),
    )) {
      state = old.copyWith(error: 'writeFailed');
      return false;
    }
    state = ProfileState(profile: nextProfile, restoring: false);
    return true;
  }

  Future<bool> saveAvatar(PlayerAvatarRef avatar) async {
    await ready;
    final envelope = await store.load(owner);
    if (!await store.save(
      owner,
      envelope.copyWith(profile: envelope.profile.copyWith(avatar: avatar)),
    )) {
      return false;
    }
    state = ProfileState(
      profile: envelope.profile.copyWith(avatar: avatar),
      restoring: false,
    );
    return true;
  }

  String _id() {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(16, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }
}

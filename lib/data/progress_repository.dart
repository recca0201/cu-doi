import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/player_progress.dart';

/// Abstraction over the progress source so a Firestore-backed implementation
/// can drop in later without touching state/UI (architecture ADR-5).
abstract class ProgressRepository {
  Future<PlayerProgress> load();
  Future<bool> save(PlayerProgress progress);
}

/// Offline-first local store. Writes are immediate and never throw up to the UI
/// (US-017 AC-1.1); infrastructure errors degrade to an empty/last-known value.
class LocalProgressRepository implements ProgressRepository {
  LocalProgressRepository(
    SharedPreferences prefs, {
    Future<bool> Function(String key, String value)? writer,
  }) : _prefs = prefs,
       _writer = writer ?? prefs.setString;
  final SharedPreferences _prefs;
  final Future<bool> Function(String key, String value) _writer;
  static const _key = 'progress_v1';

  @override
  Future<PlayerProgress> load() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return const PlayerProgress();
      return PlayerProgress.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, s) {
      dev.log(
        'load progress failed',
        name: 'data.progress',
        error: e,
        stackTrace: s,
      );
      return const PlayerProgress();
    }
  }

  @override
  Future<bool> save(PlayerProgress progress) async {
    try {
      return await _writer(_key, jsonEncode(progress.toJson()));
    } catch (e, s) {
      dev.log(
        'save progress failed',
        name: 'data.progress',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }
}

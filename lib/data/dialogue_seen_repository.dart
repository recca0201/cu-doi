import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/character.dart';

abstract class DialogueSeenRepository {
  Future<Set<DialogueId>> load();
  Future<bool> save(Set<DialogueId> seen);
}

class LocalDialogueSeenRepository implements DialogueSeenRepository {
  LocalDialogueSeenRepository(
    SharedPreferences prefs, {
    Future<bool> Function(String key, String value)? writer,
  }) : _prefs = prefs,
       _writer = writer ?? prefs.setString;

  static const String storageKey = 'dialogue_seen_v1';

  final SharedPreferences _prefs;
  final Future<bool> Function(String key, String value) _writer;

  @override
  Future<Set<DialogueId>> load() async {
    try {
      final String? raw = _prefs.getString(storageKey);
      if (raw == null) return <DialogueId>{};
      final Object? decoded = jsonDecode(raw);
      if (decoded is! List) return <DialogueId>{};
      final Map<String, DialogueId> known = <String, DialogueId>{
        for (final DialogueId id in DialogueId.values) id.name: id,
      };
      return decoded
          .whereType<String>()
          .map((String name) => known[name])
          .whereType<DialogueId>()
          .toSet();
    } catch (error, stackTrace) {
      dev.log(
        'load dialogue seen state failed',
        name: 'data.dialogue_seen',
        error: error,
        stackTrace: stackTrace,
      );
      return <DialogueId>{};
    }
  }

  @override
  Future<bool> save(Set<DialogueId> seen) async {
    try {
      final List<String> names = seen.map((DialogueId id) => id.name).toList()
        ..sort();
      return await _writer(storageKey, jsonEncode(names));
    } catch (error, stackTrace) {
      dev.log(
        'save dialogue seen state failed',
        name: 'data.dialogue_seen',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}

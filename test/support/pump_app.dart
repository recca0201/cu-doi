import 'package:ban_bua_tuong/data/dialogue_seen_repository.dart';
import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/data/settings_repository.dart';
import 'package:ban_bua_tuong/domain/character.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryProgressRepository implements ProgressRepository {
  MemoryProgressRepository(this.value);
  PlayerProgress value;

  @override
  Future<PlayerProgress> load() async => value;

  @override
  Future<bool> save(PlayerProgress progress) async {
    value = progress;
    return true;
  }
}

class MemoryDialogueSeenRepository implements DialogueSeenRepository {
  MemoryDialogueSeenRepository([Set<DialogueId>? value])
    : value = value ?? <DialogueId>{};
  Set<DialogueId> value;

  @override
  Future<Set<DialogueId>> load() async => Set<DialogueId>.of(value);

  @override
  Future<bool> save(Set<DialogueId> seen) async {
    value = Set<DialogueId>.of(seen);
    return true;
  }
}

bool _fontsLoaded = false;

Future<void> _loadFonts() async {
  if (_fontsLoaded) return;
  await Future.wait(<Future<void>>[
    (FontLoader(
      'Baloo2',
    )..addFont(rootBundle.load('assets/fonts/Baloo2-Variable.ttf'))).load(),
    (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Variable.ttf'))).load(),
  ]);
  _fontsLoaded = true;
}

Future<void> pumpApp(
  WidgetTester tester, {
  required Widget home,
  PlayerProgress progress = const PlayerProgress(),
  AppSettings settings = const AppSettings(),
  Set<DialogueId> seen = const <DialogueId>{},
  Locale locale = const Locale('vi'),
  Size size = const Size(390, 844),
  TextScaler textScaler = TextScaler.noScaling,
  List<Override> overrides = const <Override>[],
}) async {
  await _loadFonts();
  SharedPreferences.setMockInitialValues(<String, Object>{
    'soundOn': settings.soundOn,
    'musicOn': settings.musicOn,
    'hapticsOn': settings.hapticsOn,
    'localeCode': settings.localeCode,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final MemoryProgressRepository progressRepo = MemoryProgressRepository(
    progress,
  );
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        progressRepositoryProvider.overrideWithValue(progressRepo),
        progressProvider.overrideWith(
          (ref) => ProgressController(progressRepo, initial: progress),
        ),
        dialogueSeenRepositoryProvider.overrideWithValue(
          MemoryDialogueSeenRepository(seen),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: home,
        ),
      ),
    ),
  );
  await tester.pump();
}

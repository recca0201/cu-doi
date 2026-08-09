import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo implements ProgressRepository {
  _Repo(this.value);
  PlayerProgress value;
  @override
  Future<PlayerProgress> load() async => value;
  @override
  Future<bool> save(PlayerProgress progress) async {
    value = progress;
    return true;
  }
}

void main() {
  testWidgets('loss reminder includes prices and keeps retry primary', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final _Repo repo = _Repo(
      const PlayerProgress(
        coins: 500,
        results: <int, LevelResult>{1: LevelResult(losses: 1)},
      ),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          progressRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          locale: Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(arenaId: 1),
        ),
      ),
    );
    await tester.pump();
    for (int shot = 0; shot < 3; shot++) {
      await tester.tapAt(const Offset(195, 430));
      for (int i = 0; i < 180; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    expect(find.textContaining('50 xu'), findsWidgets);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(find.byKey(const Key('skip-arena-button')), findsNothing);
  });
}

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
  testWidgets('visible disabled hint control preserves the static arena hint', (
    WidgetTester tester,
  ) async {
    final _Repo repo = _Repo(const PlayerProgress());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
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
    await tester.pump(const Duration(milliseconds: 20));

    final Finder button = find.byKey(const Key('hint-button'));
    expect(button, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(find.textContaining('THIẾU 50 XU'), findsOneWidget);
    expect(find.textContaining('Bắn thẳng thì chúng nó cười'), findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(repo.value.coins, 0);
    expect(find.byType(GameScreen), findsOneWidget);
  });
}

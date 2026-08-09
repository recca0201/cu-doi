import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/l10n/app_localizations.dart';
import 'package:ban_bua_tuong/state/providers.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Repo implements ProgressRepository {
  _Repo(this.value);
  PlayerProgress value;
  @override
  Future<PlayerProgress> load() async => value;
  @override
  Future<bool> save(PlayerProgress progress) async => true;
}

Widget _app(PlayerProgress progress) => ProviderScope(
  overrides: <Override>[
    progressRepositoryProvider.overrideWithValue(_Repo(progress)),
  ],
  child: const MaterialApp(
    locale: Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ArenaMapScreen(),
  ),
);

void main() {
  testWidgets('skipped stage has a textual badge beside its stars', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PlayerProgress(
          results: <int, LevelResult>{1: LevelResult(skipped: true)},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ĐÃ BỎ QUA'), findsOneWidget);
  });

  testWidgets('a genuinely completed stage has no skipped badge', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const PlayerProgress(
          results: <int, LevelResult>{1: LevelResult(stars: 2)},
        ),
      ),
    );
    await tester.pump();
    expect(find.text('ĐÃ BỎ QUA'), findsNothing);
  });
}

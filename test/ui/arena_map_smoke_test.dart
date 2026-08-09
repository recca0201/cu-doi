import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:ban_bua_tuong/ui/screens/arena_map_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/pump_app.dart';

void main() {
  testWidgets('map pumps with seeded progress and keeps linear unlocks', (
    tester,
  ) async {
    const progress = PlayerProgress(
      results: <int, LevelResult>{3: LevelResult(stars: 1)},
    );
    expect(progress.isUnlocked(4), isTrue);
    expect(progress.isUnlocked(5), isFalse);
    await pumpApp(tester, home: const ArenaMapScreen(), progress: progress);
    expect(find.byType(ArenaMapScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

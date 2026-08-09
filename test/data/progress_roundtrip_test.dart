import 'dart:convert';

import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skip, losses and coins survive a repository roundtrip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocalProgressRepository repo = LocalProgressRepository(prefs);
    final PlayerProgress value = const PlayerProgress(
      coins: 500,
    ).withSkipped(2).withLoss(3).withLoss(3).withCoinsSpent(150);
    expect(await repo.save(value), isTrue);
    final PlayerProgress loaded = await repo.load();
    expect(loaded.coins, 350);
    expect(loaded.isSkipped(2), isTrue);
    expect(loaded.lossesFor(3), 2);

    await prefs.setString(
      'progress_v1',
      jsonEncode(<String, dynamic>{
        'coins': 77,
        'results': <String, dynamic>{
          '1': <String, dynamic>{'stars': 2, 'highScore': 800},
        },
      }),
    );
    final PlayerProgress old = await repo.load();
    expect(old.coins, 77);
    expect(old.starsFor(1), 2);
    expect(old.isSkipped(1), isFalse);
    expect(old.lossesFor(1), 0);
  });
}

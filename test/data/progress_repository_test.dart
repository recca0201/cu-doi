import 'package:ban_bua_tuong/data/progress_repository.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('save reports success and load falls back on corrupt data', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocalProgressRepository repo = LocalProgressRepository(prefs);
    expect(await repo.save(const PlayerProgress(coins: 20)), isTrue);
    expect((await repo.load()).coins, 20);

    await prefs.setString('progress_v1', '{broken');
    expect(await repo.load(), isA<PlayerProgress>());
    expect((await repo.load()).coins, 0);
  });

  test('save returns false when preferences reject or throw', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final LocalProgressRepository rejected = LocalProgressRepository(
      prefs,
      writer: (String _, String _) async => false,
    );
    expect(await rejected.save(const PlayerProgress(coins: 20)), isFalse);

    final LocalProgressRepository throwing = LocalProgressRepository(
      prefs,
      writer: (String _, String _) => Future<bool>.error(StateError('disk')),
    );
    expect(await throwing.save(const PlayerProgress(coins: 20)), isFalse);
  });
}

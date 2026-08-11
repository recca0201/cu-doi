import 'package:ban_bua_tuong/data/local_player_store.dart';
import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('owner namespaces isolate accounts and persist envelope', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = LocalPlayerStore(prefs);
    final a = OwnerKey.account('uid-a');
    final b = OwnerKey.account('uid-b');
    expect(a.storageId, isNot(contains('uid-a')));
    expect(
      await store.save(
        a,
        const PlayerEnvelope(progress: PlayerProgress(coins: 7)),
      ),
      isTrue,
    );
    expect((await store.load(a)).progress.coins, 7);
    expect((await store.load(b)).progress.coins, 0);
  });
  test('legacy progress migrates only into guest envelope', () async {
    SharedPreferences.setMockInitialValues({
      'progress_v1': '{"coins":12,"results":{}}',
    });
    final store = LocalPlayerStore(await SharedPreferences.getInstance());
    expect((await store.load(const OwnerKey.guest())).progress.coins, 12);
  });
}

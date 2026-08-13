import 'package:ban_bua_tuong/data/local_player_store.dart';
import 'package:ban_bua_tuong/domain/player_profile.dart';
import 'package:ban_bua_tuong/state/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'edit cancel, validation, durable normalized name and pending mutation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalPlayerStore(await SharedPreferences.getInstance());
      final controller = ProfileController(store, const OwnerKey.guest());
      await controller.ready;
      controller.beginNameEdit();
      controller.updateDraft('  Dội   Giỏi  ');
      controller.cancelEdit();
      expect(controller.state.profile.customDisplayName, isNull);
      expect(await controller.saveName('   '), isFalse);
      expect(controller.state.error, 'empty');
      expect(await controller.saveName('  Dội   Giỏi  '), isTrue);
      final saved = await store.load(const OwnerKey.guest());
      expect(saved.profile.customDisplayName, 'Dội Giỏi');
      expect(saved.pending, hasLength(1));
      expect(saved.pending.single.id, isNotEmpty);
    },
  );

  test(
    'save waits for restore before replacing the claimed account name',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = LocalPlayerStore(await SharedPreferences.getInstance());
      final owner = OwnerKey.account('google-user');
      await store.save(
        owner,
        const PlayerEnvelope(
          profile: PlayerProfile(customDisplayName: 'Tên khách cũ'),
        ),
      );
      final controller = ProfileController(store, owner);

      expect(await controller.saveName('Tên Google'), isTrue);

      expect(controller.state.profile.customDisplayName, 'Tên Google');
      expect((await store.load(owner)).profile.customDisplayName, 'Tên Google');
    },
  );
}

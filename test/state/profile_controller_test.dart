import 'package:ban_bua_tuong/data/local_player_store.dart';
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
      await Future<void>.delayed(Duration.zero);
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
}

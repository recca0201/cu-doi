import 'package:ban_bua_tuong/data/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'default guest bootstrap is local-only and requires no production options',
    () async {
      expect(FirebaseBootstrap.useEmulator, isFalse);
      final result = await FirebaseBootstrap.initialize();
      expect(result.enabled, isFalse);
      expect(result.emulator, isFalse);
    },
  );
}

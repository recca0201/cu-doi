import 'package:ban_bua_tuong/data/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an explicit guest bootstrap is local-only', () async {
    expect(FirebaseBootstrap.useEmulator, isFalse);
    expect(FirebaseBootstrap.enableProduction, isTrue);
    final result = await FirebaseBootstrap.initialize(productionEnabled: false);
    expect(result.enabled, isFalse);
    expect(result.emulator, isFalse);
  });
}

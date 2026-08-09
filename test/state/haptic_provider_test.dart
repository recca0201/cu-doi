import 'package:ban_bua_tuong/state/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('settings update the existing haptic service instance', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(container.dispose);
    final service = container.read(hapticServiceProvider);
    container.read(settingsProvider.notifier).setHaptics(false);
    await pumpEventQueue();
    expect(container.read(hapticServiceProvider), same(service));
    expect(service.enabled, isFalse);
  });
}

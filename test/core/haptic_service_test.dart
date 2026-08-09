import 'package:ban_bua_tuong/core/haptic_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final List<MethodCall> calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('four events map to four platform patterns', () async {
    DateTime clock = DateTime(2026);
    final HapticService service = HapticService(
      enabled: true,
      now: () => clock,
    );
    for (final HapticEvent event in HapticEvent.values) {
      service.fire(event);
      clock = clock.add(const Duration(milliseconds: 70));
    }
    await pumpEventQueue();
    expect(calls, hasLength(4));
    expect(calls.toSet(), hasLength(4));
  });

  test('gameplay shares 60ms while level end is exempt', () async {
    DateTime clock = DateTime(2026);
    final HapticService service = HapticService(
      enabled: true,
      now: () => clock,
    );
    service.fire(HapticEvent.bank);
    clock = clock.add(const Duration(milliseconds: 20));
    service.fire(HapticEvent.targetBroken);
    expect(calls, hasLength(1));
    clock = clock.add(const Duration(milliseconds: 50));
    service.fire(HapticEvent.targetBroken);
    clock = clock.add(const Duration(milliseconds: 16));
    service.fire(HapticEvent.levelEnd);
    await pumpEventQueue();
    expect(calls, hasLength(3));
    expect(kHapticCooldown, const Duration(milliseconds: 60));
  });

  test('disabled and rejected platform calls are harmless', () async {
    final HapticService service = HapticService(enabled: false);
    service.fire(HapticEvent.bank);
    expect(calls, isEmpty);
    service.setEnabled(true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall _,
        ) async {
          throw PlatformException(code: 'unsupported');
        });
    service.fire(HapticEvent.bank);
    await pumpEventQueue();
  });
}

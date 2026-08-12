import 'dart:async';

import 'package:ban_bua_tuong/domain/economy.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/hint_finder.dart';
import 'package:ban_bua_tuong/state/hint_controller.dart';
import 'package:flutter_test/flutter_test.dart';

ArenaSnapshot _snapshot(int id) => ArenaSnapshot(
  segments: const <Segment>[],
  targets: const [],
  alive: const <bool>[],
  origin: const V2(50, 150),
  arenaId: id,
);

const HintShot _shot = HintShot(
  aim: V2(0, -1),
  path: <V2>[V2(50, 150), V2(10, 10)],
  targetIndices: <int>[2],
);

void main() {
  test('insufficient coins does not start the finder', () async {
    int scans = 0;
    final HintController controller = HintController(
      () async => SpendResult.ok,
      () => false,
      (ArenaSnapshot _) async {
        scans++;
        return _shot;
      },
    );
    await controller.request(_snapshot(1));
    expect(controller.state.status, HintStatus.insufficientCoins);
    expect(scans, 0);
  });

  test(
    'computing ignores duplicate request and unavailable spends nothing',
    () async {
      final Completer<HintShot?> gate = Completer<HintShot?>();
      int spends = 0;
      int scans = 0;
      final HintController controller = HintController(
        () async {
          spends++;
          return SpendResult.ok;
        },
        () => true,
        (ArenaSnapshot _) {
          scans++;
          return gate.future;
        },
      );
      final Future<void> first = controller.request(_snapshot(1));
      expect(controller.state.status, HintStatus.computing);
      await controller.request(_snapshot(1));
      expect(scans, 1);
      gate.complete(null);
      await first;
      expect(controller.state.status, HintStatus.unavailable);
      expect(spends, 0);
    },
  );

  test('shown path has the required arena lifecycle', () async {
    int spends = 0;
    final HintController controller = HintController(
      () async {
        spends++;
        return SpendResult.ok;
      },
      () => true,
      (ArenaSnapshot _) async => _shot,
    );
    await controller.request(_snapshot(2));
    expect(controller.state.status, HintStatus.shown);
    expect(controller.state.targetIndices, <int>[2]);
    expect(spends, 1);
    controller.clearOnShot();
    expect(controller.state.path, isEmpty);
    expect(controller.state.targetIndices, isEmpty);
    expect(controller.state.purchasedPath, isNotEmpty);
    controller.onArenaLoaded(2);
    expect(controller.state.path, controller.state.purchasedPath);
    expect(controller.state.targetIndices, <int>[2]);
    expect(spends, 1);
    controller.clearOnShot();
    await controller.request(_snapshot(2));
    expect(spends, 2);
    controller.onArenaLoaded(3);
    expect(controller.state.path, isEmpty);
    expect(controller.state.purchasedPath, isEmpty);
    expect(controller.state.purchasedForArenaId, isNull);
  });

  test('finder and write failures are exposed separately', () async {
    final HintController finderFailure = HintController(
      () async => SpendResult.ok,
      () => true,
      (ArenaSnapshot _) => Future<HintShot?>.error(StateError('scan')),
    );
    await finderFailure.request(_snapshot(1));
    expect(finderFailure.state.status, HintStatus.failed);

    final HintController writeFailure = HintController(
      () async => SpendResult.writeFailed,
      () => true,
      (ArenaSnapshot _) async => _shot,
    );
    await writeFailure.request(_snapshot(1));
    expect(writeFailure.state.status, HintStatus.failed);
    expect(writeFailure.state.path, isEmpty);
  });
}

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/sim/geometry.dart';
import 'package:ban_bua_tuong/sim/shot_runner.dart';
import 'package:ban_bua_tuong/ui/comic_effect_controller.dart';
import 'package:flutter_test/flutter_test.dart';

ShotEvent event(
  ShotEventKind kind, {
  int banks = 0,
  V2 pos = const V2(10, 10),
}) => ShotEvent(kind, pos, bankCount: banks);

void main() {
  test('events select tiers from authoritative banks-at-event', () {
    final ComicEffectController effects = ComicEffectController();
    effects.onEvent(event(ShotEventKind.bank, banks: 99), banksAtEvent: 3);
    effects.onEvent(event(ShotEventKind.broke), banksAtEvent: 3);
    effects.onEvent(event(ShotEventKind.blocked), banksAtEvent: 2);
    expect(effects.elements.map((e) => e.tier.level), <int>[3, 4, 2]);

    effects.onEvent(event(ShotEventKind.bank), banksAtEvent: 0);
    expect(effects.elements, hasLength(3));
  });

  test('blocked target contact does not make later bank effects climb', () {
    final ComicEffectController effects = ComicEffectController();
    effects.onEvent(event(ShotEventKind.bank), banksAtEvent: 1);
    effects.onEvent(event(ShotEventKind.blocked), banksAtEvent: 1);
    effects.onEvent(event(ShotEventKind.bank), banksAtEvent: 2);
    expect(effects.elements.map((e) => e.tier.level), <int>[1, 1, 2]);
  });

  test('elements age out, accumulate, and evict oldest at the cap', () {
    final ComicEffectController effects = ComicEffectController();
    effects.onEvent(event(ShotEventKind.broke), banksAtEvent: 2);
    effects.onEvent(
      event(ShotEventKind.broke, pos: const V2(11, 10)),
      banksAtEvent: 2,
    );
    expect(effects.elements, hasLength(2));
    effects.tick(effects.elements.first.tier.duration + .001);
    expect(effects.elements, isEmpty);

    for (int i = 0; i < 30; i++) {
      effects.onEvent(
        event(ShotEventKind.broke, pos: V2(i.toDouble(), 10)),
        banksAtEvent: 2,
      );
    }
    expect(effects.elements, hasLength(kMaxEffectElements));
    expect(effects.elements.first.pos.x, 6);
  });

  test('end reason only clears a shot that exits through the floor', () {
    for (final ShotEndReason reason in ShotEndReason.values) {
      final ComicEffectController effects = ComicEffectController();
      effects.onEvent(event(ShotEventKind.bank), banksAtEvent: 1);
      effects.endShot(reason);
      expect(effects.isNotEmpty, reason != ShotEndReason.exitedBottom);
    }
  });

  test('effects never retain a center inside a living target glow', () {
    final ComicEffectController effects = ComicEffectController();
    const TargetSpec target = TargetSpec(V2(10, 10), 1);
    effects.onEvent(
      event(ShotEventKind.bank),
      banksAtEvent: 2,
      targets: const <TargetSpec>[target],
      alive: const <bool>[true],
    );
    expect(effects.elements, isEmpty);
  });
}

import 'package:ban_bua_tuong/sim/arena.dart';
import 'package:ban_bua_tuong/ui/comic_effect_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('effect tiers grow through the usable bank range and cap at it', () {
    expect(EffectTier.forLevel(0), isNull);
    for (int level = 1; level < kMaxBanks - 1; level++) {
      final EffectTier a = EffectTier.forLevel(level)!;
      final EffectTier b = EffectTier.forLevel(level + 1)!;
      expect(b.duration, greaterThan(a.duration));
      expect(b.spokeCount, greaterThan(a.spokeCount));
      expect(b.spokeLength, greaterThan(a.spokeLength));
      expect(b.spokeWidth, greaterThan(a.spokeWidth));
    }
    final EffectTier two = EffectTier.forLevel(2)!;
    final EffectTier three = EffectTier.forLevel(3)!;
    final EffectTier peak = EffectTier.forLevel(kMaxBanks - 1)!;
    expect(
      peak.duration - three.duration,
      greaterThan(three.duration - two.duration),
    );
    expect(
      peak.spokeCount - three.spokeCount,
      greaterThan(three.spokeCount - two.spokeCount),
    );
    expect(
      peak.spokeLength - three.spokeLength,
      greaterThan(three.spokeLength - two.spokeLength),
    );
    expect(
      peak.spokeWidth - three.spokeWidth,
      greaterThan(three.spokeWidth - two.spokeWidth),
    );
    expect(EffectTier.forLevel(kMaxBanks), same(peak));
    expect(kMaxEffectElements, 24);
  });
}

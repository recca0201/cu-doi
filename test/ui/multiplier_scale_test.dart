import 'package:ban_bua_tuong/core/bb_tokens.dart';
import 'package:ban_bua_tuong/ui/arena_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final double light = a.computeLuminance();
  final double dark = b.computeLuminance();
  return (light + .05) / (dark + .05);
}

void main() {
  test('multiplier grows and gold-on-navy is readable', () {
    expect(multiplierFontSizeForBanks(0), greaterThan(0));
    expect(
      multiplierFontSizeForBanks(4),
      greaterThan(multiplierFontSizeForBanks(1)),
    );
    expect(
      contrast(BbTokens.primaryGold, BbTokens.panelNavy),
      greaterThanOrEqualTo(3),
    );
  });
}

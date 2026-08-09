import 'package:flutter/material.dart';
import 'bb_tokens.dart';

/// Text styles — Baloo 2 for display/headings/**all numbers**, Nunito for body.
abstract final class BbText {
  static const displayFamily = 'Baloo2';
  static const bodyFamily = 'Nunito';

  static TextStyle logo([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 64,
    fontWeight: FontWeight.w800,
    color: c,
    height: 1.05,
  );
  static TextStyle display([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: c,
    height: 1.05,
  );
  static TextStyle h1([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: c,
    height: 1.1,
  );
  static TextStyle h2([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: c,
    height: 1.2,
  );
  static TextStyle h3([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: c,
    height: 1.2,
  );
  static TextStyle score([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    color: c,
    height: 1.0,
  );
  static TextStyle body([Color c = BbTokens.ink700]) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: c,
    height: 1.4,
  );
  static TextStyle small([Color c = BbTokens.ink500]) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: c,
    height: 1.3,
  );
  static TextStyle tiny([Color c = BbTokens.ink900]) => TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: c,
    letterSpacing: 0.08 * 12,
  );
  static TextStyle button([Color c = Colors.white]) => TextStyle(
    fontFamily: displayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: c,
    height: 1.0,
  );
}

abstract final class BbTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: BbTokens.bbCoral,
        primary: BbTokens.bbCoral,
        secondary: BbTokens.bbTeal,
        surface: BbTokens.surface,
      ),
      scaffoldBackgroundColor: BbTokens.cream,
    );
    return base.copyWith(
      textTheme: base.textTheme
          .apply(fontFamily: BbText.bodyFamily)
          .apply(bodyColor: BbTokens.ink700, displayColor: BbTokens.ink900),
    );
  }
}

import 'package:flutter/widgets.dart';

import 'bb_tokens.dart';

/// The arena palette.
///
/// Brand continuity is deliberate and load-bearing: the four target colours,
/// the amber frame, the ink outline and the cream are the *same* hues as
/// `BbTokens`, so this still reads as Bắn Bừa. What changes is the stage — the
/// parent game's daylight cream-and-sky playfield becomes a night arena, because
/// the thing being sold is a computed carom, not a cheerful bubble grid.
///
/// Colours are stored as 0xRRGGBB ints rather than as `Color`, for one specific
/// reason: alpha variants have to be built somehow, and every convenient way of
/// doing that from an existing `Color` has churned between Flutter versions
/// (`withOpacity` deprecated in favour of `withValues`; `.red`/`.green`/`.blue`
/// deprecated in favour of `.r`/`.g`/`.b`). `Color.fromARGB` with plain ints has
/// never moved. The duplication against `BbTokens` is the price, and the
/// comments below are the contract — if a brand hue changes, change it here too.
abstract final class ArenaInk {
  static Color of(int rgb, [int alpha = 255]) =>
      Color.fromARGB(alpha, (rgb >> 16) & 0xFF, (rgb >> 8) & 0xFF, rgb & 0xFF);

  /// Night stage. No `BbTokens` equivalent — the parent brand has no dark mode.
  static const int bgTop = 0x171238;
  static const int bgBottom = 0x2C1F5C;
  static const int panelNavy = 0x151B3E;
  static const int galaxyIndigo = 0x12073E;
  static const int galaxyPurple = 0x7127D6;
  static const int galaxyMagenta = 0xFF3FE6;
  static const int energyCyan = 0x40E8FF;
  static const int metalBlue = 0x16356F;

  static const int frame = 0xFFC93C; // == BbTokens.bbYellow
  static const int primaryGold = frame;
  static const int trajectoryCyan = 0x7FCBFF;
  static const int outline = 0x2B2038; // == BbTokens.ink900
  static const int cream = 0xFFF6E9; // == BbTokens.cream
  static const int danger = 0xFF4D4D; // == BbTokens.danger
  static const int deflector = 0x7FCBFF; // == BbTokens.skyDeep
  static const int blockFill = 0x140F26; // darkened ink900

  static const int hintAlpha = 0xE6;
  static const double hintStrokeWidth = 0.85;
  static const double hintDash = 2.6;
  static const double hintGap = 1.8;
  static const double hintWaypointRadius = 1.8;

  /// Target colours, in the brand's own order.
  static const List<int> targets = <int>[
    0xFF5A8C, // BbTokens.bbCoral
    0x2CC4B4, // BbTokens.bbTeal
    0xFFC93C, // BbTokens.bbYellow
    0xA66BFF, // BbTokens.bbGrape
  ];

  /// Sanity anchor for tests: these must stay in step with [BbTokens].
  static const List<Color> brandSources = <Color>[
    BbTokens.bbCoral,
    BbTokens.bbTeal,
    BbTokens.bbYellow,
    BbTokens.bbGrape,
  ];
}

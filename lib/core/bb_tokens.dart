import 'package:flutter/widgets.dart';

/// Design tokens ported 1:1 from the `Bắn Bừa Design System` (tokens/*.css).
/// Never use raw hex or magic px in widgets — always reference [BbTokens].
abstract final class BbTokens {
  // --- Arcade-night semantic palette ---
  static const nightIndigo = Color(0xFF090D2A);
  static const panelNavy = Color(0xFF151B3E);
  static const karstDeep = Color(0xFF042D31);
  static const karstTeal = Color(0xFF07504A);
  static const karstBronze = Color(0xFFD99A38);
  static const primaryGold = Color(0xFFFFC21C);
  static const primaryGoldDark = Color(0xFFD99B00);
  static const secondaryBlue = Color(0xFF1976D2);
  static const secondaryBlueDark = Color(0xFF1056A2);
  static const tertiaryPurple = Color(0xFF7E32C8);
  static const dangerRed = Color(0xFFF04444);
  static const trajectoryCyan = Color(0xFF54D9FF);
  static const successGreen = Color(0xFF7ED321);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textMuted = Color(0xFFAAB2D5);
  static const outlineDark = Color(0xFF080B1B);

  // --- Brand ---
  static const bbCoral = Color(0xFFFF5A8C);
  static const bbCoralDark = Color(0xFFE63E72);
  static const bbCoralSoft = Color(0xFFFFD9E5);
  static const bbTeal = Color(0xFF2CC4B4);
  static const bbTealDark = Color(0xFF1FA294);
  static const bbTealSoft = Color(0xFFC9F2ED);
  static const bbYellow = Color(0xFFFFC93C);
  static const bbYellowDark = Color(0xFFE8A81F);
  static const bbGrape = Color(0xFFA66BFF);
  static const bbGrapeDark = Color(0xFF8A48EE);

  // --- Ink / surface ---
  static const ink900 = Color(0xFF2B2038);
  static const ink700 = Color(0xFF4A3C5C);
  static const ink500 = Color(0xFF7A6B8C);
  static const ink300 = Color(0xFFC9BFD6);
  static const ink100 = Color(0xFFEFE9F5);
  static const cream = Color(0xFFFFF6E9);
  static const creamDeep = Color(0xFFFBE9CF);
  static const surface = Color(0xFFFFFFFF);
  static const sky = Color(0xFFBDE6FF);
  static const skyDeep = Color(0xFF7FCBFF);

  // --- Semantic ---
  static const success = Color(0xFF3FBF6A);
  static const successSoft = Color(0xFFD6F5E1);
  static const danger = Color(0xFFFF4D4D);
  static const dangerSoft = Color(0xFFFFDCDC);
  static const warning = Color(0xFFFFB020);
  static const warningSoft = Color(0xFFFFEFC9);
  static const info = Color(0xFF4EA8FF);
  static const infoSoft = Color(0xFFD6ECFF);

  // --- Spacing (4px grid) ---
  static const sp1 = 4.0;
  static const sp2 = 8.0;
  static const sp3 = 12.0;
  static const sp4 = 16.0;
  static const sp5 = 20.0;
  static const sp6 = 24.0;
  static const sp7 = 32.0;
  static const sp8 = 40.0;
  static const sp9 = 48.0;
  static const sp10 = 64.0;

  static const tapMin = 48.0;
  static const btnHSm = 40.0;
  static const btnHMd = 52.0;
  static const btnHLg = 64.0;
  static const bubbleSize = 56.0;
  static const screenMax = 440.0;
  static const gutter = 20.0;

  /// Android's conventional tablet cutoff. This includes 7-inch devices,
  /// whose shortest logical edge is commonly exactly 600dp.
  static const tabletBreakpoint = 600.0;

  /// Tablets use a wider 9:16 card instead of stretching the narrow phone
  /// composition across a large display.
  static const _tabletCardAspect = 9.0 / 16.0;

  /// Largest the card is allowed to grow, so a 13" iPad does not end up with
  /// comically oversized controls.
  static const _cardMax = 820.0;

  /// Max content width for the sticker-card layout every screen uses.
  ///
  /// Phones keep [screenMax] exactly. Tablets grow to a 9:16 composition that
  /// leaves breathing room without the oversized side gutters of the phone
  /// aspect ratio.
  ///
  /// Holding a consistent tablet aspect ratio is important, not just widening:
  /// [BubbleGame] derives bubble radius from width as
  /// `size.x / (2 * level.cols + 1)`, so a wider playfield scales bubbles up
  /// while the column count stays fixed. Growing width without height would
  /// make bubbles bigger relative to the playfield and fit fewer rows before
  /// the danger line — i.e. quietly change difficulty. Scaling both keeps
  /// every level playing exactly as designed.
  static double contentMaxWidth(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide < tabletBreakpoint) return screenMax;
    final byHeight = size.height * _tabletCardAspect;
    final byWidth = size.width;
    return (byHeight < byWidth ? byHeight : byWidth).clamp(screenMax, _cardMax);
  }

  /// How much larger the card is than the phone design width — 1.0 on phones.
  ///
  /// Art sized in absolute pixels (the brand hero, for instance) does not grow
  /// just because the card did, so it ends up marooned in empty space on a
  /// tablet. Multiply those fixed dimensions by this to keep the composition
  /// proportional. Layout that already derives from width needs no scaling.
  static double contentScale(BuildContext context) =>
      contentMaxWidth(context) / screenMax;

  // --- Radii ---
  static const rSm = 10.0;
  static const rMd = 16.0;
  static const rLg = 24.0;
  static const rXl = 32.0;
  static const rPill = 999.0;

  // --- Borders ---
  static const bd2 = 3.0;
  static const bd3 = 4.0;
  static const bd4 = 6.0;

  // --- Motion ---
  static const durFast = Duration(milliseconds: 120);
  static const durBase = Duration(milliseconds: 200);
  static const durSlow = Duration(milliseconds: 340);
  static const easeBounce = Cubic(.34, 1.56, .64, 1);
  static const easeOut = Cubic(.22, .61, .36, 1);
  static const pressDrop = 3.0;

  /// Sticker shadow — hard offset, NEVER blurred. The #1 brand signature.
  static List<BoxShadow> sticker(double offset, [Color color = ink900]) => [
    BoxShadow(offset: Offset(offset, offset), blurRadius: 0, color: color),
  ];

  static const stickerSm = 3.0;
  static const stickerMd = 5.0;
  static const stickerLg = 8.0;
}

import 'package:flutter/material.dart';
import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';

enum BbVariant { primary, secondary, accent, grape, danger, light, karst }

enum BbSize { sm, md, lg }

enum BbTitleTone { standard, victory, danger }

/// Comic wordmark for localized and dynamic screen titles.
class BbGameTitle extends StatelessWidget {
  const BbGameTitle({
    super.key,
    required this.label,
    this.tone = BbTitleTone.standard,
    this.height = 58,
    this.fontSize = 48,
    this.tilt = -.018,
    this.textAlign = TextAlign.center,
  });

  final String label;
  final BbTitleTone tone;
  final double height;
  final double fontSize;
  final double tilt;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final List<Color> fill = switch (tone) {
      BbTitleTone.standard => const <Color>[
        Colors.white,
        Color(0xFFE9FAFF),
        Color(0xFFFFC21C),
      ],
      BbTitleTone.victory => const <Color>[
        Color(0xFFFFFF8A),
        Color(0xFFFFC21C),
        Color(0xFFFF8A00),
      ],
      BbTitleTone.danger => const <Color>[
        Color(0xFFFFF1EA),
        Color(0xFFFF694F),
        Color(0xFFD91F3A),
      ],
    };
    final Color extrusion = tone == BbTitleTone.danger
        ? const Color(0xFF721438)
        : BbTokens.secondaryBlueDark;
    final Paint foreground = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: fill,
        stops: const <double>[0, .48, 1],
      ).createShader(Rect.fromLTWH(0, 0, fontSize * 12, fontSize * 1.2));
    final List<Shadow> shadows = <Shadow>[
      Shadow(color: extrusion, offset: const Offset(-1, 8)),
      Shadow(color: extrusion, offset: const Offset(1, 8)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(-3, -2)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(3, -2)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(-4, 1)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(4, 1)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(-3, 4)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(3, 4)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(0, -4)),
      const Shadow(color: BbTokens.outlineDark, offset: Offset(0, 5)),
      const Shadow(
        color: Color(0x6654D9FF),
        offset: Offset(0, 7),
        blurRadius: 7,
      ),
    ];

    return Semantics(
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Transform.rotate(
                angle: tilt,
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  textAlign: textAlign,
                  style: BbText.logo().copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1,
                    letterSpacing: -1.2,
                    foreground: foreground,
                    shadows: shadows,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VariantSpec {
  const _VariantSpec({
    required this.top,
    required this.bottom,
    required this.rim,
    required this.shadow,
    required this.fg,
  });
  final Color top, bottom, rim, shadow, fg;
}

const _variants = {
  BbVariant.primary: _VariantSpec(
    top: Color(0xFFFFE64A),
    bottom: Color(0xFFFFA800),
    rim: Color(0xFFFFF07A),
    shadow: Color(0xFF8A4A00),
    fg: Color(0xFF3B2100),
  ),
  BbVariant.secondary: _VariantSpec(
    top: Color(0xFF32BFFF),
    bottom: Color(0xFF0863C8),
    rim: Color(0xFF92E7FF),
    shadow: Color(0xFF052D69),
    fg: Colors.white,
  ),
  BbVariant.accent: _VariantSpec(
    top: Color(0xFFC45AF5),
    bottom: Color(0xFF7023C5),
    rim: Color(0xFFE4A4FF),
    shadow: Color(0xFF38106E),
    fg: Colors.white,
  ),
  BbVariant.grape: _VariantSpec(
    top: Color(0xFFB474FF),
    bottom: Color(0xFF7131C7),
    rim: Color(0xFFD7B1FF),
    shadow: Color(0xFF351361),
    fg: Colors.white,
  ),
  BbVariant.danger: _VariantSpec(
    top: Color(0xFFFF6255),
    bottom: Color(0xFFC91422),
    rim: Color(0xFFFFB1A8),
    shadow: Color(0xFF670E18),
    fg: Colors.white,
  ),
  BbVariant.light: _VariantSpec(
    top: Color(0xFF274E93),
    bottom: Color(0xFF102553),
    rim: Color(0xFF6FA6E8),
    shadow: Color(0xFF050A1C),
    fg: BbTokens.textPrimary,
  ),
  BbVariant.karst: _VariantSpec(
    top: Color(0xFF15947F),
    bottom: Color(0xFF07504A),
    rim: Color(0xFFFFD36A),
    shadow: Color(0xFF3D210E),
    fg: Color(0xFFFFF3D7),
  ),
};

/// Signature sticker-pill CTA with the "press-drop" physics (US design system).
class BbButton extends StatefulWidget {
  const BbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BbVariant.primary,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  });

  const BbButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.primary;
  const BbButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.secondary;
  const BbButton.accent({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.accent;
  const BbButton.light({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.light;
  const BbButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.danger;
  const BbButton.karst({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BbSize.md,
    this.icon,
    this.expand = false,
    this.selected,
  }) : variant = BbVariant.karst;

  final String label;
  final VoidCallback? onPressed;
  final BbVariant variant;
  final BbSize size;
  final IconData? icon;
  final bool expand;
  final bool? selected;

  @override
  State<BbButton> createState() => _BbButtonState();
}

class _BbButtonState extends State<BbButton> {
  bool _down = false;

  double get _height => switch (widget.size) {
    BbSize.sm => BbTokens.btnHSm,
    BbSize.md => BbTokens.btnHMd,
    BbSize.lg => BbTokens.btnHLg,
  };

  @override
  Widget build(BuildContext context) {
    final tablet =
        MediaQuery.sizeOf(context).shortestSide >= BbTokens.tabletBreakpoint;
    final controlScale = tablet ? 1.18 : 1.0;
    final inheritedTextScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final buttonTextScale = tablet && inheritedTextScale < 1.18
        ? 1.18
        : inheritedTextScale;
    final spec = _variants[widget.variant]!;
    final enabled = widget.onPressed != null;
    final pressed = _down && enabled;
    final drop = pressed ? BbTokens.pressDrop : 0.0;
    final shadowOffset = pressed ? 1.0 : BbTokens.stickerMd + 1;
    final top = pressed ? Color.lerp(spec.top, spec.bottom, .5)! : spec.top;

    Widget child = AnimatedContainer(
      duration: BbTokens.durFast,
      curve: BbTokens.easeOut,
      height: _height * controlScale,
      transform: Matrix4.translationValues(drop, drop, 0),
      // An alignment loosens the child's constraints. For expanded buttons
      // that made only the black outer shell fill the row while the coloured
      // face shrank to the label's intrinsic width.
      alignment: widget.expand ? null : Alignment.center,
      decoration: BoxDecoration(
        color: BbTokens.outlineDark,
        borderRadius: BorderRadius.circular(BbTokens.rPill),
        border: Border.all(color: const Color(0xFF050816), width: 2.5),
        boxShadow: enabled
            ? <BoxShadow>[
                BoxShadow(
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                  color: spec.shadow,
                ),
              ]
            : const [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[top, spec.bottom],
              stops: const <double>[0, .82],
            ),
            borderRadius: BorderRadius.circular(BbTokens.rPill - 3),
            border: Border.all(color: spec.rim, width: 1.5),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.white.withValues(alpha: .32),
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: SizedBox(
            height: _height * controlScale - 4,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Positioned(
                  left: 14,
                  right: 14,
                  top: 3,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .62),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: BbTokens.sp5 * controlScale,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      if (widget.icon != null) ...<Widget>[
                        Icon(
                          widget.icon,
                          color: spec.fg,
                          size:
                              (widget.size == BbSize.lg ? 28 : 21) *
                              controlScale,
                          shadows: const <Shadow>[
                            Shadow(color: Colors.black45, offset: Offset(0, 2)),
                          ],
                        ),
                        SizedBox(width: BbTokens.sp2 * controlScale),
                      ],
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            textScaler: TextScaler.linear(buttonTextScale),
                            style: BbText.button(spec.fg).copyWith(
                              fontSize: widget.size == BbSize.lg
                                  ? 22
                                  : (widget.size == BbSize.sm ? 15 : 18),
                              shadows: const <Shadow>[
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!enabled) child = Opacity(opacity: 0.5, child: child);

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: widget.expand
              ? SizedBox(width: double.infinity, child: child)
              : child,
        ),
      ),
    );
  }
}

/// Large, layered launcher button used by the home screen.
///
/// The label is centred against the whole button, while the icon occupies its
/// own space on the left. This matches the optical alignment in the key art.
class BbMenuButton extends StatefulWidget {
  const BbMenuButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.icon,
    this.variant = BbVariant.primary,
    this.hero = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final BbVariant variant;
  final bool hero;

  @override
  State<BbMenuButton> createState() => _BbMenuButtonState();
}

class _BbMenuButtonState extends State<BbMenuButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final _VariantSpec spec = _variants[widget.variant]!;
    final bool enabled = widget.onPressed != null;
    final bool pressed = enabled && _down;
    final double height = widget.hero ? 86 : 62;
    final double radius = widget.hero ? 30 : 20;
    final double drop = pressed ? BbTokens.pressDrop : 0;
    final double shadowOffset = pressed ? 2 : (widget.hero ? 8 : 6);
    final double iconSize = widget.hero ? 42 : 27;
    final double iconLeft = widget.hero ? 24 : 10;
    final double labelFontSize = widget.hero ? 36 : 22;
    final double labelReserve = widget.hero ? 74 : 38;
    final Color top = pressed
        ? Color.lerp(spec.top, spec.bottom, .46)!
        : spec.top;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: AnimatedOpacity(
            duration: BbTokens.durFast,
            opacity: enabled ? 1 : .52,
            child: AnimatedContainer(
              duration: BbTokens.durFast,
              curve: BbTokens.easeOut,
              height: height,
              transform: Matrix4.translationValues(drop, drop, 0),
              decoration: BoxDecoration(
                color: BbTokens.outlineDark,
                borderRadius: BorderRadius.circular(radius + 3),
                border: Border.all(color: const Color(0xFF030510), width: 3),
                boxShadow: enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: spec.shadow,
                          offset: Offset(0, shadowOffset),
                          blurRadius: 0,
                        ),
                        if (widget.hero && !pressed)
                          BoxShadow(
                            color: BbTokens.primaryGold.withValues(alpha: .2),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[top, spec.bottom],
                      stops: const <double>[0, .8],
                    ),
                    borderRadius: BorderRadius.circular(radius - 1),
                    border: Border.all(color: spec.rim, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius - 3),
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Positioned(
                          left: widget.hero ? 28 : 18,
                          right: widget.hero ? 28 : 18,
                          top: 5,
                          child: Container(
                            height: widget.hero ? 7 : 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .56),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        Positioned(
                          left: iconLeft,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Icon(
                              widget.icon,
                              size: iconSize,
                              color: spec.fg,
                              shadows: const <Shadow>[
                                Shadow(
                                  color: BbTokens.outlineDark,
                                  offset: Offset(-2, 0),
                                ),
                                Shadow(
                                  color: BbTokens.outlineDark,
                                  offset: Offset(2, 0),
                                ),
                                Shadow(
                                  color: BbTokens.outlineDark,
                                  offset: Offset(0, -2),
                                ),
                                Shadow(
                                  color: BbTokens.outlineDark,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: labelReserve,
                              vertical: 8,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _OutlinedButtonLabel(
                                widget.label.toUpperCase(),
                                color: spec.fg,
                                fontSize: labelFontSize,
                                outlineWidth: widget.hero ? 1.4 : 3,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: radius,
                          right: radius,
                          bottom: 3,
                          child: Container(
                            height: 3,
                            color: spec.shadow.withValues(alpha: .42),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ImageGen-backed button that keeps Flutter semantics and press feedback.
class BbAssetButton extends StatefulWidget {
  const BbAssetButton({
    super.key,
    required this.asset,
    required this.height,
    required this.semanticLabel,
    required this.onPressed,
    this.width = double.infinity,
    this.fit = BoxFit.fill,
    this.horizontalScale = 1,
    this.hiddenText,
  });

  final String asset;
  final double width;
  final double height;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final BoxFit fit;
  final double horizontalScale;
  final String? hiddenText;

  @override
  State<BbAssetButton> createState() => _BbAssetButtonState();
}

class _BbAssetButtonState extends State<BbAssetButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final bool pressed = enabled && _down;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: AnimatedOpacity(
            duration: BbTokens.durFast,
            opacity: enabled ? 1 : .48,
            child: AnimatedContainer(
              duration: BbTokens.durFast,
              curve: BbTokens.easeOut,
              width: widget.width,
              height: widget.height,
              transform: Matrix4.translationValues(
                0,
                pressed ? BbTokens.pressDrop : 0,
                0,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ClipRect(
                    child: Transform.scale(
                      scaleX: widget.horizontalScale,
                      child: Image.asset(
                        widget.asset,
                        fit: widget.fit,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  if (widget.hiddenText != null)
                    Opacity(
                      opacity: 0,
                      child: Center(child: Text(widget.hiddenText!)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gold/bronze CTA used by the karst visual language.
///
/// The source sprite has a 1890:691 aspect ratio. Keeping that ratio here is
/// important: stretching it to the width of a row makes the bronze ornaments
/// and the label area look unnaturally long.
class BbKarstPlayButton extends StatefulWidget {
  const BbKarstPlayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  State<BbKarstPlayButton> createState() => _BbKarstPlayButtonState();
}

class _BbKarstPlayButtonState extends State<BbKarstPlayButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final bool pressed = enabled && _down;
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.label,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: AnimatedOpacity(
            duration: BbTokens.durFast,
            opacity: enabled ? 1 : .48,
            child: AnimatedContainer(
              duration: BbTokens.durFast,
              transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
              height: widget.height,
              width: widget.height * (1890 / 691),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    'assets/images/ui/karst/play_button.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      widget.height * .92,
                      widget.height * .12,
                      widget.height * .28,
                      widget.height * .13,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label.toUpperCase(),
                        maxLines: 1,
                        style: BbText.button(
                          const Color(0xFF572600),
                        ).copyWith(fontSize: widget.height * .43, height: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedButtonLabel extends StatelessWidget {
  const _OutlinedButtonLabel(
    this.text, {
    required this.color,
    required this.fontSize,
    required this.outlineWidth,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = BbText.button(
      color,
    ).copyWith(fontSize: fontSize, height: 1, letterSpacing: -.25);
    return Stack(
      children: <Widget>[
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: style.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeWidth = outlineWidth
              ..color = BbTokens.outlineDark,
          ),
        ),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: style.copyWith(
            shadows: const <Shadow>[
              Shadow(color: Colors.black45, offset: Offset(0, 2)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Galaxy jewel icon button used by the HUD and screen navigation.
class BbIconButton extends StatefulWidget {
  const BbIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = BbVariant.light,
    this.semanticLabel,
    this.diameter = BbTokens.tapMin,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final BbVariant variant;
  final String? semanticLabel;
  final double diameter;

  @override
  State<BbIconButton> createState() => _BbIconButtonState();
}

class _BbIconButtonState extends State<BbIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final spec = _variants[widget.variant]!;
    final enabled = widget.onPressed != null;
    final pressed = _down && enabled;
    final drop = pressed ? BbTokens.pressDrop : 0.0;
    final shadowOffset = pressed ? 1.0 : BbTokens.stickerSm + 1;
    final radius = widget.diameter * .28;
    final top = pressed ? Color.lerp(spec.top, spec.bottom, .5)! : spec.top;
    final iconDiameter = widget.diameter * .67;
    final bool karst = widget.variant == BbVariant.karst;

    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      onTap: enabled ? widget.onPressed : null,
      child: ExcludeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapUp: enabled ? (_) => setState(() => _down = false) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: BbTokens.durFast,
            curve: BbTokens.easeOut,
            width: widget.diameter,
            height: widget.diameter,
            transform: Matrix4.translationValues(0, drop, 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: karst
                    ? const <Color>[
                        Color(0xFFFFE2A0),
                        Color(0xFFD99A38),
                        Color(0xFF087064),
                        Color(0xFF3D210E),
                      ]
                    : <Color>[
                        Colors.white.withValues(alpha: .95),
                        spec.rim,
                        Color.lerp(spec.top, spec.bottom, .5)!,
                        BbTokens.outlineDark,
                      ],
                stops: const <double>[0, .18, .62, 1],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: BbTokens.outlineDark, width: 2.4),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  offset: Offset(0, shadowOffset),
                  blurRadius: 0,
                  color: spec.shadow,
                ),
                if (!pressed)
                  BoxShadow(
                    color: spec.rim.withValues(alpha: .35),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(widget.diameter * .075),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Color.lerp(top, Colors.white, .16)!,
                      spec.bottom,
                      Color.lerp(spec.bottom, BbTokens.outlineDark, .38)!,
                    ],
                    stops: const <double>[0, .58, 1],
                  ),
                  borderRadius: BorderRadius.circular(radius - 2),
                  border: Border.all(
                    color: karst
                        ? const Color(0xFFFFD36A)
                        : Colors.white.withValues(alpha: .5),
                    width: 1.2,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .42),
                      offset: const Offset(0, 2),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      left: widget.diameter * .16,
                      right: widget.diameter * .16,
                      top: widget.diameter * .09,
                      child: Container(
                        height: widget.diameter * .055,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    Container(
                      width: iconDiameter,
                      height: iconDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-.28, -.35),
                          radius: .92,
                          colors: <Color>[
                            Colors.white.withValues(alpha: .28),
                            top,
                            spec.bottom,
                          ],
                          stops: const <double>[0, .48, 1],
                        ),
                        border: Border.all(color: spec.rim, width: 1.35),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: BbTokens.outlineDark.withValues(alpha: .75),
                            offset: const Offset(0, 2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          Icon(
                            widget.icon,
                            color: BbTokens.outlineDark,
                            size: widget.diameter * .53,
                          ),
                          Icon(
                            widget.icon,
                            color: spec.fg,
                            size: widget.diameter * .43,
                            shadows: const <Shadow>[
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: widget.diameter * .18,
                      top: widget.diameter * .17,
                      child: Container(
                        width: widget.diameter * .075,
                        height: widget.diameter * .075,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: .9),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Colors.white, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grouped content surface with ink border + optional sticker shadow.
class BbCard extends StatelessWidget {
  const BbCard({
    super.key,
    required this.child,
    this.color = BbTokens.panelNavy,
    this.padding = const EdgeInsets.all(BbTokens.sp5),
    this.sticker = true,
    this.radius = BbTokens.rLg,
    this.borderColor = BbTokens.outlineDark,
    this.shadowColor = BbTokens.outlineDark,
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final bool sticker;
  final double radius;
  final Color borderColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor, width: BbTokens.bd3),
      boxShadow: sticker
          ? BbTokens.sticker(BbTokens.stickerMd, shadowColor)
          : const [],
    ),
    child: child,
  );
}

/// Small ALL-CAPS pill for tags / counts / combo / "MỚI".
class BbBadge extends StatelessWidget {
  const BbBadge(
    this.text, {
    super.key,
    this.color = BbTokens.bbYellow,
    this.fg = BbTokens.ink900,
  });
  final String text;
  final Color color;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: BbTokens.sp3,
      vertical: BbTokens.sp1,
    ),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(BbTokens.rPill),
      border: Border.all(color: BbTokens.ink900, width: BbTokens.bd2),
      boxShadow: BbTokens.sticker(BbTokens.stickerSm),
    ),
    child: Text(text.toUpperCase(), style: BbText.tiny(fg)),
  );
}

/// Chunky settings switch — thumb slides with bounce; on = blue, off = muted.
class BbToggle extends StatelessWidget {
  const BbToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    toggled: value,
    label: semanticLabel,
    onTap: () => onChanged(!value),
    child: ExcludeSemantics(
      child: GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: SizedBox(
          width: 64,
          height: BbTokens.tapMin,
          child: Center(
            child: AnimatedContainer(
              duration: BbTokens.durBase,
              curve: BbTokens.easeBounce,
              width: 64,
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: value
                      ? const <Color>[Color(0xFF15947F), Color(0xFF07504A)]
                      : const <Color>[Color(0xFF6E6250), Color(0xFF3D352C)],
                ),
                borderRadius: BorderRadius.circular(BbTokens.rPill),
                border: Border.all(
                  color: BbTokens.karstBronze,
                  width: BbTokens.bd2,
                ),
              ),
              child: AnimatedAlign(
                duration: BbTokens.durBase,
                curve: BbTokens.easeBounce,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3D7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF3D210E),
                      width: BbTokens.bd2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Central popup shell: surface panel, thick ink border, big sticker shadow.
class BbDialog extends StatelessWidget {
  const BbDialog({
    super.key,
    required this.child,
    this.color = BbTokens.karstDeep,
  });
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        margin: const EdgeInsets.all(BbTokens.sp6),
        padding: const EdgeInsets.all(BbTokens.sp7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(BbTokens.rXl),
          border: Border.all(color: BbTokens.karstBronze, width: BbTokens.bd4),
          boxShadow: BbTokens.sticker(BbTokens.stickerLg, BbTokens.outlineDark),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [child]),
      ),
    ),
  );
}

/// Show a [BbDialog]-style overlay: ink scrim + bounce scale-in.
Future<T?> showBbDialog<T>(
  BuildContext context,
  WidgetBuilder builder, {
  bool dismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'dialog',
    barrierColor: Colors.black.withValues(alpha: 0.78),
    transitionDuration: BbTokens.durSlow,
    pageBuilder: (ctx, a1, a2) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
      scale: Tween(
        begin: 0.7,
        end: 1.0,
      ).animate(CurvedAnimation(parent: anim, curve: BbTokens.easeBounce)),
      child: FadeTransition(opacity: anim, child: child),
    ),
  );
}

/// Compact VI/EN pill switch (GAME_SPEC §5) — white sticker capsule with the
/// active language on a coral chip.
class BbLangToggle extends StatelessWidget {
  const BbLangToggle({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  final String locale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: BbTokens.surface,
      borderRadius: BorderRadius.circular(BbTokens.rPill),
      border: Border.all(color: BbTokens.ink900, width: BbTokens.bd3),
      boxShadow: BbTokens.sticker(BbTokens.stickerSm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _option('vi', 'VI'),
        const SizedBox(width: 2),
        _option('en', 'EN'),
      ],
    ),
  );

  Widget _option(String code, String label) {
    final active = locale == code;
    return Semantics(
      container: true,
      button: true,
      selected: active,
      label: label,
      onTap: () => onChanged(code),
      child: ExcludeSemantics(
        child: GestureDetector(
          excludeFromSemantics: true,
          onTap: () => onChanged(code),
          child: AnimatedContainer(
            duration: BbTokens.durFast,
            curve: BbTokens.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: active ? BbTokens.bbCoral : Colors.transparent,
              borderRadius: BorderRadius.circular(BbTokens.rPill),
            ),
            child: Text(
              label,
              style: BbText.button(
                active ? Colors.white : BbTokens.ink500,
              ).copyWith(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

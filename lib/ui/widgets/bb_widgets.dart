import 'package:flutter/material.dart';
import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';

enum BbVariant { primary, secondary, accent, grape, danger, light }

enum BbSize { sm, md, lg }

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
      alignment: Alignment.center,
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

/// Round icon-only button (HUD chrome: pause, speaker, back) — same press physics.
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
    final shadowOffset = pressed ? 1.0 : BbTokens.stickerSm + 2;
    final radius = widget.diameter * .24;
    final top = pressed ? Color.lerp(spec.top, spec.bottom, .5)! : spec.top;

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
            transform: Matrix4.translationValues(drop, drop, 0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BbTokens.outlineDark,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: const Color(0xFF050816), width: 2.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  offset: Offset(shadowOffset, shadowOffset),
                  blurRadius: 0,
                  color: spec.shadow,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[top, spec.bottom],
                  ),
                  borderRadius: BorderRadius.circular(radius - 3),
                  border: Border.all(color: spec.rim, width: 1.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.white.withValues(alpha: .35),
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      left: 7,
                      right: 7,
                      top: 3,
                      child: Container(
                        height: 2,
                        color: Colors.white.withValues(alpha: .5),
                      ),
                    ),
                    Icon(
                      widget.icon,
                      color: spec.fg,
                      size: widget.diameter * .48,
                      shadows: const <Shadow>[
                        Shadow(color: Colors.black54, offset: Offset(0, 2)),
                      ],
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
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final bool sticker;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: BbTokens.outlineDark, width: BbTokens.bd3),
      boxShadow: sticker
          ? BbTokens.sticker(BbTokens.stickerMd, BbTokens.outlineDark)
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
                color: value ? BbTokens.secondaryBlue : BbTokens.textMuted,
                borderRadius: BorderRadius.circular(BbTokens.rPill),
                border: Border.all(
                  color: BbTokens.outlineDark,
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
                    color: BbTokens.textPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BbTokens.outlineDark,
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
    this.color = BbTokens.panelNavy,
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
          border: Border.all(color: BbTokens.outlineDark, width: BbTokens.bd4),
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

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/chapters.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/geometry.dart';
import '../../sim/shot_runner.dart';
import '../../state/providers.dart';
import '../localized_text.dart';
import '../map_sections.dart';
import '../pangolin_ball_art.dart';
import '../widgets/bb_backdrop.dart';
import '../widgets/bb_widgets.dart';
import 'game_screen.dart';

class ArenaMapScreen extends ConsumerStatefulWidget {
  const ArenaMapScreen({this.targetArenaId, super.key});

  final int? targetArenaId;

  @override
  ConsumerState<ArenaMapScreen> createState() => _ArenaMapScreenState();
}

class _ArenaMapScreenState extends ConsumerState<ArenaMapScreen> {
  static const double _rowExtent = 176;

  late final List<ChapterSection> _sections;
  ScrollController? _controller;
  int _chapterIndex = 0;
  int _selectedArenaId = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    _sections = buildMapSections();
    final PlayerProgress progress = ref.read(progressProvider);
    final int target =
        targetLevelId(progress, requestedArenaId: widget.targetArenaId) ?? 1;
    final int sectionIndex = _sections.indexWhere(
      (ChapterSection section) =>
          section.arenas.any((ArenaSpec arena) => arena.id == target),
    );
    _chapterIndex = sectionIndex < 0 ? 0 : sectionIndex;
    _selectedArenaId = target;
    final int indexInChapter = _sections[_chapterIndex].arenas.indexWhere(
      (ArenaSpec arena) => arena.id == target,
    );
    _controller = ScrollController(
      initialScrollOffset: indexInChapter > 0 ? 1 : 0,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final PlayerProgress progress = ref.watch(progressProvider);
    final String localeCode = Localizations.localeOf(context).languageCode;
    final ChapterSection section = _sections[_chapterIndex];
    final ArenaSpec selected = section.arenas.firstWhere(
      (ArenaSpec arena) => arena.id == _selectedArenaId,
      orElse: () => section.arenas.first,
    );
    final double textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final double detailHeight = 244 + math.max(0, textScale - 1) * 92;

    return Scaffold(
      backgroundColor: BbTokens.karstDeep,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const BbCanyonBackdrop(scrim: .42, bottomShade: .66),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.45),
                  radius: 1.1,
                  colors: <Color>[
                    const Color(0xFFFFC56A).withValues(alpha: .16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: BbKarstFrameOverlay()),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: <Widget>[
                        const _MapAppBar(),
                        _ChapterTabs(
                          sections: _sections,
                          selectedIndex: _chapterIndex,
                          progress: progress,
                          onSelected: (int index) => setState(() {
                            _chapterIndex = index;
                            final ChapterSection next = _sections[index];
                            _selectedArenaId = next.arenas
                                .firstWhere(
                                  (ArenaSpec arena) =>
                                      progress.isUnlocked(arena.id),
                                  orElse: () => next.arenas.first,
                                )
                                .id;
                            if (_controller!.hasClients) _controller!.jumpTo(0);
                          }),
                        ),
                        Expanded(
                          child: CustomScrollView(
                            key: const Key('arena-map-scroll'),
                            controller: _controller,
                            slivers: <Widget>[
                              SliverToBoxAdapter(
                                child: _ChapterProgress(
                                  section: section,
                                  progress: progress,
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  4,
                                  12,
                                  0,
                                ),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        mainAxisExtent: _rowExtent,
                                        crossAxisSpacing: 9,
                                        mainAxisSpacing: 10,
                                      ),
                                  delegate: SliverChildBuilderDelegate((
                                    BuildContext context,
                                    int index,
                                  ) {
                                    final ArenaSpec arena =
                                        section.arenas[index];
                                    return _ArenaCard(
                                      key: ValueKey<String>(
                                        'arena-${arena.id}',
                                      ),
                                      arena: arena,
                                      localeCode: localeCode,
                                      state: _stateFor(arena.id, progress),
                                      stars: progress.starsFor(arena.id),
                                      selected: arena.id == selected.id,
                                      onTap: () => _selectOrExplain(
                                        context,
                                        t,
                                        arena,
                                        progress,
                                      ),
                                    );
                                  }, childCount: section.arenas.length),
                                ),
                              ),
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 150),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: detailHeight,
                          child: _ArenaDetailPanel(
                            arena: selected,
                            localeCode: localeCode,
                            progress: progress,
                            onPlay: progress.isUnlocked(selected.id)
                                ? () => _play(selected)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ArenaNodeState _stateFor(int id, PlayerProgress progress) {
    if (progress.isCompleted(id)) return _ArenaNodeState.completed;
    if (progress.isSkipped(id)) return _ArenaNodeState.skipped;
    if (!progress.isUnlocked(id)) return _ArenaNodeState.locked;
    if (id == progress.unlockedMax) return _ArenaNodeState.current;
    return _ArenaNodeState.unlocked;
  }

  void _selectOrExplain(
    BuildContext context,
    AppLocalizations t,
    ArenaSpec arena,
    PlayerProgress progress,
  ) {
    if (!progress.isUnlocked(arena.id)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.arenaLockedHint)));
      return;
    }
    setState(() => _selectedArenaId = arena.id);
  }

  void _play(ArenaSpec arena) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameScreen(arenaId: arena.id),
      ),
    );
  }
}

abstract final class _MapArt {
  static const String backButton = 'assets/images/ui/karst/back_button.png';
  static String selectTitle(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'en'
      ? 'assets/images/ui/karst/stage_title_banner_en_v1.png'
      : 'assets/images/ui/karst/stage_title_banner_v2.png';
  static const String levelCardFrame =
      'assets/images/ui/karst/level_card_frame.png';
  static const String detailPanel =
      'assets/images/ui/karst/detail_panel_rect_v2.png';
  static const String playButton = 'assets/images/ui/karst/play_button.png';
}

class _MapSpriteButton extends StatelessWidget {
  const _MapSpriteButton({
    required this.asset,
    required this.width,
    required this.height,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String asset;
  final double width;
  final double height;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: semanticLabel,
    onTap: onPressed,
    child: ExcludeSemantics(
      child: Opacity(
        opacity: onPressed == null ? .48 : 1,
        child: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                asset,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MapImageTextButton extends StatelessWidget {
  const _MapImageTextButton({
    super.key,
    required this.asset,
    required this.height,
    required this.label,
    required this.onPressed,
  });

  final String asset;
  final double height;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: label,
    child: ExcludeSemantics(
      child: Opacity(
        opacity: onPressed == null ? .48 : 1,
        child: SizedBox(
          height: height,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(height / 2),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    asset,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                  Positioned(
                    left: height * .82,
                    right: height * .22,
                    top: 0,
                    bottom: height * .20,
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: BbText.button(
                            const Color(0xFF572600),
                          ).copyWith(fontSize: 24),
                        ),
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

class _MapAppBar extends StatelessWidget {
  const _MapAppBar();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      key: const Key('arena-map-header'),
      height: 104,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 0,
            top: 8,
            child: _MapSpriteButton(
              asset: _MapArt.backButton,
              width: 48,
              height: 48,
              semanticLabel: t.backCta,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 58,
            right: 58,
            child: Semantics(
              header: true,
              label: t.arenaSelectTitle,
              child: ExcludeSemantics(
                child: SizedBox(
                  key: const Key('arena-map-title'),
                  height: 80,
                  child: Image.asset(
                    _MapArt.selectTitle(context),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterTabs extends StatelessWidget {
  const _ChapterTabs({
    required this.sections,
    required this.selectedIndex,
    required this.progress,
    required this.onSelected,
  });

  final List<ChapterSection> sections;
  final int selectedIndex;
  final PlayerProgress progress;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return SizedBox(
      key: const Key('chapter-journey'),
      height: 72,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double cellWidth = constraints.maxWidth / sections.length;
          return Stack(
            alignment: Alignment.topCenter,
            children: <Widget>[
              Positioned(
                left: cellWidth / 2,
                right: cellWidth / 2,
                top: 29,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: BbTokens.karstShadow,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: BbTokens.karstBronze),
                  ),
                ),
              ),
              Row(
                children: List<Widget>.generate(sections.length, (int index) {
                  final ChapterSection section = sections[index];
                  final bool selected = index == selectedIndex;
                  final String full = chapterTitle(section.chapter, t);
                  final int earned = section.arenas.fold(
                    0,
                    (int sum, ArenaSpec arena) =>
                        sum + progress.starsFor(arena.id),
                  );
                  final int max = section.arenas.length * 3;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: full,
                      value: t.chapterProgressLabel(earned, max),
                      child: InkResponse(
                        key: ValueKey<String>('chapter-${index + 1}'),
                        onTap: () => onSelected(index),
                        radius: 34,
                        containedInkWell: true,
                        customBorder: const CircleBorder(),
                        child: Center(
                          child: AnimatedScale(
                            scale: selected ? 1 : .86,
                            duration: BbTokens.durBase,
                            curve: BbTokens.easeOut,
                            child: _ChapterMedallion(
                              number: section.chapter?.number ?? index + 1,
                              progress: max == 0 ? 0 : earned / max,
                              selected: selected,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChapterMedallion extends StatelessWidget {
  const _ChapterMedallion({
    required this.number,
    required this.progress,
    required this.selected,
  });

  final int number;
  final double progress;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 64,
    height: 64,
    child: CustomPaint(
      painter: _ChapterMedallionPainter(progress: progress, selected: selected),
      child: Center(
        child: Text(
          '$number',
          textScaler: TextScaler.noScaling,
          style: BbText.h2(
            selected ? BbTokens.karstShadow : BbTokens.cream,
          ).copyWith(fontSize: 24, height: 1),
        ),
      ),
    ),
  );
}

class _ChapterMedallionPainter extends CustomPainter {
  const _ChapterMedallionPainter({
    required this.progress,
    required this.selected,
  });

  final double progress;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = size.shortestSide / 2;
    final Rect ring = Rect.fromCircle(center: center, radius: radius - 5);

    canvas.drawCircle(
      center + const Offset(0, 4),
      radius - 4,
      Paint()..color = BbTokens.karstShadow,
    );
    canvas.drawCircle(
      center,
      radius - 4,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? const <Color>[BbTokens.cream, BbTokens.primaryGold]
              : const <Color>[BbTokens.karstTeal, BbTokens.karstDeep],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      radius - 5,
      Paint()
        ..color = BbTokens.karstBronze
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      math.pi * 2 * progress.clamp(0, 1),
      false,
      Paint()
        ..color = BbTokens.primaryGold
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 5 : 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      center,
      radius - 12,
      Paint()
        ..color = selected
            ? Colors.white.withValues(alpha: .28)
            : BbTokens.cream.withValues(alpha: .13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ChapterMedallionPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.selected != selected;
}

class _ChapterProgress extends StatelessWidget {
  const _ChapterProgress({required this.section, required this.progress});

  final ChapterSection section;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final int earned = section.arenas.fold(
      0,
      (int sum, ArenaSpec arena) => sum + progress.starsFor(arena.id),
    );
    final int max = section.arenas.length * 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.transparent,
                        BbTokens.karstBronze.withValues(alpha: .8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.explore_rounded,
                size: 17,
                color: BbTokens.primaryGold,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        BbTokens.karstBronze.withValues(alpha: .8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    chapterTitle(section.chapter, AppLocalizations.of(context)),
                    maxLines: 1,
                    style: BbText.h3(BbTokens.cream).copyWith(fontSize: 17),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: BbTokens.primaryGold,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).chapterProgressLabel(earned, max),
                    style: BbText.small(BbTokens.primaryGold),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ArenaNodeState { locked, unlocked, current, completed, skipped }

class _ArenaCard extends StatelessWidget {
  const _ArenaCard({
    super.key,
    required this.arena,
    required this.localeCode,
    required this.state,
    required this.stars,
    required this.selected,
    required this.onTap,
  });

  final ArenaSpec arena;
  final String localeCode;
  final _ArenaNodeState state;
  final int stars;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool locked = state == _ArenaNodeState.locked;
    final bool skipped = state == _ArenaNodeState.skipped;
    final String arenaName = forLocale(localeCode, arena.name, arena.nameEn);
    final String stateLabel = locked
        ? t.arenaLocked
        : (skipped ? t.arenaSkippedBadge : t.arenaStars(stars, 3));

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !locked,
      label: '${t.arenaHeading(arena.id, arenaName)}, $stateLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double width = constraints.maxWidth;
                final double height = constraints.maxHeight;
                // These ratios follow the transparent opening in the authored
                // 1074 x 1522 frame. Keeping the preview inside this aperture
                // lets the bronze/green rails remain visible on every device.
                final Rect previewRect = Rect.fromLTRB(
                  width * .195,
                  height * .19,
                  width * .805,
                  height * .815,
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    if (selected)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 5,
                            sigmaY: 5,
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              BbTokens.primaryGold,
                              BlendMode.srcIn,
                            ),
                            child: Image.asset(
                              _MapArt.levelCardFrame,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ),
                    Positioned.fromRect(
                      rect: previewRect,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _ArenaPreview(arena: arena, locked: locked),
                      ),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: locked ? .62 : 1,
                        child: Image.asset(
                          _MapArt.levelCardFrame,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 3,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SizedBox(
                          width: 54,
                          height: 40,
                          child: Center(
                            child: Text(
                              '${arena.id}',
                              style: BbText.h2(
                                locked ? BbTokens.textMuted : Colors.white,
                              ).copyWith(fontSize: 23),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      // Keep status content inside the green inset panel of
                      // the authored frame instead of covering its gold rim.
                      left: width * .23,
                      right: width * .23,
                      bottom: 12,
                      height: 16,
                      child: skipped
                          ? Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  t.arenaSkippedBadge.toUpperCase(),
                                  style: BbText.tiny(
                                    BbTokens.textMuted,
                                  ).copyWith(fontSize: 8),
                                ),
                              ),
                            )
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  3,
                                  (int i) => Icon(
                                    i < stars
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: i < stars
                                        ? BbTokens.primaryGold
                                        : BbTokens.textMuted,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (locked)
                      Positioned.fromRect(
                        rect: previewRect,
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            size: 38,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ArenaDetailPanel extends StatelessWidget {
  const _ArenaDetailPanel({
    required this.arena,
    required this.localeCode,
    required this.progress,
    required this.onPlay,
  });

  final ArenaSpec arena;
  final String localeCode;
  final PlayerProgress progress;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String name = forLocale(localeCode, arena.name, arena.nameEn);
    final double previewWidth = (MediaQuery.sizeOf(context).width * .24).clamp(
      84.0,
      112.0,
    );
    return Container(
      key: const Key('arena-detail-panel'),
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.asset(
              _MapArt.detailPanel,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            // Insets follow the larger clear field of the 3:2 panel asset.
            padding: const EdgeInsets.fromLTRB(34, 25, 34, 24),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        key: const Key('selected-arena-preview'),
                        width: previewWidth,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _ArenaPreview(
                            arena: arena,
                            locked: onPlay == null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      t.arenaNumberLabel(arena.id),
                                      maxLines: 1,
                                      style: BbText.h2(
                                        Colors.white,
                                      ).copyWith(fontSize: 22),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  color: BbTokens.primaryGold,
                                ),
                                Text(
                                  '${progress.starsFor(arena.id)}',
                                  style: BbText.h3(BbTokens.primaryGold),
                                ),
                              ],
                            ),
                            FittedBox(
                              alignment: Alignment.centerLeft,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                name,
                                maxLines: 1,
                                style: BbText.h3(
                                  BbTokens.primaryGold,
                                ).copyWith(fontSize: 15, height: 1.05),
                              ),
                            ),
                            const SizedBox(height: 4),
                            _DetailLine(
                              icon: Icons.track_changes_rounded,
                              label: t.arenaTargetsLabel,
                              value: '${arena.targets.length}',
                            ),
                            _DetailLine(
                              icon: Icons.circle_rounded,
                              label: t.arenaBankRequirementsLabel,
                              value: arena.targets
                                  .map(
                                    (TargetSpec target) => target.requiredBanks,
                                  )
                                  .join(' / '),
                            ),
                            _DetailLine(
                              icon: Icons.bolt_rounded,
                              label: t.arenaShotsLabel,
                              value: '${arena.shots}',
                            ),
                            _DetailLine(
                              icon: Icons.star_rounded,
                              label: t.arenaStarThresholdsLabel,
                              value: arena.starThresholds.join(' / '),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: .62,
                    child: _MapImageTextButton(
                      key: const Key('selected-arena-play'),
                      asset: _MapArt.playButton,
                      height: 54,
                      label: t.playCta.toUpperCase(),
                      onPressed: onPlay,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      children: <Widget>[
        Icon(icon, size: 14, color: BbTokens.primaryGold),
        const SizedBox(width: 4),
        Expanded(
          flex: 4,
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              '$label:',
              maxLines: 1,
              style: BbText.small(Colors.white).copyWith(fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 3,
          child: FittedBox(
            alignment: Alignment.centerRight,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: BbText.small(
                BbTokens.trajectoryCyan,
              ).copyWith(fontSize: 11),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArenaPreview extends StatelessWidget {
  const _ArenaPreview({required this.arena, required this.locked});

  final ArenaSpec arena;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final List<V2> path = previewPath(
      segments: buildSegments(arena),
      targets: arena.targets,
      alive: List<bool>.filled(arena.targets.length, true),
      origin: kShooterOrigin,
      direction: const V2(.28, -1),
    );
    return CustomPaint(
      painter: _ArenaPreviewPainter(arena: arena, path: path, locked: locked),
      size: Size.infinite,
    );
  }
}

class _ArenaPreviewPainter extends CustomPainter {
  const _ArenaPreviewPainter({
    required this.arena,
    required this.path,
    required this.locked,
  });

  final ArenaSpec arena;
  final List<V2> path;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF4EADC0), Color(0xFF173D42)],
        ).createShader(Offset.zero & size),
    );
    final Path ridge = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * .62)
      ..lineTo(size.width * .18, size.height * .48)
      ..lineTo(size.width * .31, size.height * .67)
      ..lineTo(size.width * .54, size.height * .43)
      ..lineTo(size.width * .72, size.height * .64)
      ..lineTo(size.width, size.height * .51)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      ridge,
      Paint()..color = const Color(0xFF24564C).withValues(alpha: .66),
    );
    final double scale = math.min(size.width / 100, size.height / 160);
    final double dx = (size.width - 100 * scale) / 2;
    final double dy = (size.height - 160 * scale) / 2;
    Offset point(V2 p) => Offset(dx + p.x * scale, dy + p.y * scale);

    final Rect field = Rect.fromLTWH(dx, dy, 100 * scale, 160 * scale);
    canvas.drawRect(
      field,
      Paint()
        ..color = const Color(0xFF416993)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, scale * 2),
    );
    for (final BlockSpec block in arena.blocks) {
      final Rect rect = Rect.fromPoints(
        point(V2(block.left, block.top)),
        point(V2(block.right, block.bottom)),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(scale * 2)),
        Paint()..color = const Color(0xFF61789D),
      );
    }
    for (final DeflectorSpec deflector in arena.deflectors) {
      canvas.drawLine(
        point(deflector.a),
        point(deflector.b),
        Paint()
          ..color = const Color(0xFF90A8CA)
          ..strokeWidth = math.max(2, scale * 4)
          ..strokeCap = StrokeCap.round,
      );
    }
    if (!locked && path.length > 1) {
      final Paint route = Paint()
        ..color = BbTokens.trajectoryCyan
        ..strokeWidth = math.max(1, scale * 1.4)
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < path.length - 1; i++) {
        _dashed(canvas, point(path[i]), point(path[i + 1]), route);
      }
    }
    const List<Color> colors = <Color>[
      BbTokens.bbCoral,
      BbTokens.bbTeal,
      BbTokens.primaryGold,
      BbTokens.tertiaryPurple,
    ];
    for (final TargetSpec target in arena.targets) {
      final Offset center = point(target.pos);
      final double radius = math.max(5, scale * 7);
      paintPangolinBall(
        canvas,
        center: center,
        radius: radius,
        shellColor: colors[target.palette % colors.length],
        number: target.requiredBanks,
        showFace: false,
      );
    }
    final Offset launcher = point(kShooterOrigin);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: launcher,
          width: math.max(12, scale * 15),
          height: math.max(9, scale * 11),
        ),
        Radius.circular(scale * 3),
      ),
      Paint()..color = BbTokens.secondaryBlue,
    );
    canvas.drawCircle(
      launcher - Offset(0, scale * 6),
      math.max(3, scale * 4),
      Paint()..color = BbTokens.trajectoryCyan,
    );
    if (locked) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.black.withValues(alpha: .58),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArenaPreviewPainter oldDelegate) =>
      oldDelegate.arena != arena || oldDelegate.locked != locked;
}

void _dashed(Canvas canvas, Offset from, Offset to, Paint paint) {
  final double length = (to - from).distance;
  if (length == 0) return;
  final Offset direction = (to - from) / length;
  for (double d = 0; d < length; d += 8) {
    canvas.drawLine(
      from + direction * d,
      from + direction * math.min(d + 4, length),
      paint,
    );
  }
}

class ArenaSkippedBadge extends StatelessWidget {
  const ArenaSkippedBadge({super.key});

  @override
  Widget build(BuildContext context) => BbBadge(
    AppLocalizations.of(context).arenaSkippedBadge,
    color: BbTokens.panelNavy,
    fg: BbTokens.textMuted,
  );
}

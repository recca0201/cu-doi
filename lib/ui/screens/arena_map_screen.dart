import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/chapters.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../state/providers.dart';
import '../localized_text.dart';
import '../map_sections.dart';
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
  static const double _leadingPad = BbTokens.sp3;
  static const double _rowExtent = 112;
  static const double _sectionGap = BbTokens.sp5;

  ScrollController? _controller;
  late List<ChapterSection> _sections;
  late double _headerExtent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A controller is intentionally created once. Locale/text-scale changes
    // must never drag the player back after they have scrolled by hand.
    if (_controller != null) return;
    _sections = buildMapSections();
    final double textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    _headerExtent = 72 + math.max(0, textScale - 1) * 32;
    final MediaQueryData media = MediaQuery.of(context);
    final double viewport = math.max(
      1,
      media.size.height - media.padding.vertical - 80,
    );
    final double contentExtent = _contentExtent(_sections);
    final MapGridMetrics metrics = MapGridMetrics(
      leadingPad: _leadingPad,
      headerExtent: _headerExtent,
      rowExtent: _rowExtent,
      sectionGap: _sectionGap,
      viewportExtent: viewport,
      maxScrollExtent: math.max(0, contentExtent - viewport),
    );
    final PlayerProgress progress = ref.read(progressProvider);
    final int? target = targetLevelId(
      progress,
      requestedArenaId: widget.targetArenaId,
    );
    _controller = ScrollController(
      initialScrollOffset: target == null
          ? 0
          : offsetForLevel(_sections, target, metrics),
    );
  }

  double _contentExtent(List<ChapterSection> sections) {
    double result = _leadingPad;
    for (final ChapterSection section in sections) {
      final int rows = (section.arenas.length / 4).ceil();
      result += _headerExtent + rows * _rowExtent + _sectionGap;
    }
    return result;
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

    return Scaffold(
      backgroundColor: BbTokens.nightIndigo,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: BbDotPattern(color: BbTokens.trajectoryCyan, opacity: 0.08),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: BbTokens.screenMax),
                child: Column(
                  children: <Widget>[
                    _MapAppBar(progress: progress),
                    Expanded(
                      child: CustomScrollView(
                        key: const Key('arena-map-scroll'),
                        controller: _controller,
                        slivers: <Widget>[
                          const SliverToBoxAdapter(
                            child: SizedBox(height: _leadingPad),
                          ),
                          for (final ChapterSection section
                              in _sections) ...<Widget>[
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: _headerExtent,
                                child: _ChapterHeader(
                                  section: section,
                                  progress: progress,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: BbTokens.gutter,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 4,
                                      mainAxisExtent: _rowExtent,
                                      crossAxisSpacing: BbTokens.sp2,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  BuildContext context,
                                  int index,
                                ) {
                                  final ArenaSpec arena = section.arenas[index];
                                  return _ArenaNode(
                                    key: ValueKey<String>('arena-${arena.id}'),
                                    arena: arena,
                                    localeCode: localeCode,
                                    state: _stateFor(arena.id, progress),
                                    stars: progress.starsFor(arena.id),
                                    onTap: () => _openOrExplain(
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
                              child: SizedBox(height: _sectionGap),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  void _openOrExplain(
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => GameScreen(arenaId: arena.id),
      ),
    );
  }
}

class _MapAppBar extends StatelessWidget {
  const _MapAppBar({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    return Container(
      key: const Key('arena-map-header'),
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: BbTokens.sp4),
      decoration: const BoxDecoration(
        color: BbTokens.panelNavy,
        border: Border(
          bottom: BorderSide(color: BbTokens.outlineDark, width: BbTokens.bd2),
        ),
      ),
      child: Row(
        children: <Widget>[
          BbIconButton(
            icon: Icons.arrow_back_rounded,
            semanticLabel: t.backCta,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: BbTokens.sp3),
          Expanded(
            child: Text(
              t.arenaSelectTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BbText.h3(BbTokens.textPrimary),
            ),
          ),
          const Icon(Icons.star_rounded, color: BbTokens.primaryGold),
          const SizedBox(width: BbTokens.sp1),
          Text(
            '${progress.totalStars}',
            style: BbText.h3(BbTokens.primaryGold),
          ),
        ],
      ),
    );
  }
}

class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({required this.section, required this.progress});

  final ChapterSection section;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final int earned = section.arenas.fold(
      0,
      (int sum, ArenaSpec arena) => sum + progress.starsFor(arena.id),
    );
    final int max = section.arenas.length * 3;
    final String title = chapterTitle(section.chapter, t);
    final String label = '$title, ${t.chapterProgressLabel(earned, max)}';
    return Semantics(
      container: true,
      header: true,
      label: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BbTokens.gutter),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BbText.h3(BbTokens.textPrimary),
                ),
              ),
              const SizedBox(width: BbTokens.sp2),
              Text(
                t.chapterProgressLabel(earned, max),
                style: BbText.small(BbTokens.primaryGold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ArenaNodeState { locked, unlocked, current, completed, skipped }

class _ArenaNode extends StatelessWidget {
  const _ArenaNode({
    super.key,
    required this.arena,
    required this.localeCode,
    required this.state,
    required this.stars,
    required this.onTap,
  });

  final ArenaSpec arena;
  final String localeCode;
  final _ArenaNodeState state;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final String arenaName = forLocale(localeCode, arena.name, arena.nameEn);
    final String stateLabel = switch (state) {
      _ArenaNodeState.locked => t.arenaLocked,
      _ArenaNodeState.current => t.currentLevelBadge,
      _ArenaNodeState.skipped => t.arenaSkippedBadge,
      _ArenaNodeState.completed => t.arenaStars(stars, 3),
      _ArenaNodeState.unlocked => t.arenaStars(0, 3),
    };
    final bool locked = state == _ArenaNodeState.locked;
    final bool current = state == _ArenaNodeState.current;
    final bool skipped = state == _ArenaNodeState.skipped;
    final Color outline = current
        ? BbTokens.primaryGold
        : (locked ? BbTokens.textMuted : BbTokens.trajectoryCyan);

    return Semantics(
      container: true,
      button: true,
      enabled: !locked,
      label: '${t.arenaHeading(arena.id, arenaName)}, $stateLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BbTokens.rLg),
          child: SizedBox(
            height: _ArenaMapScreenState._rowExtent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: locked
                        ? BbTokens.panelNavy.withValues(alpha: 0.62)
                        : BbTokens.panelNavy,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: outline,
                      width: current ? BbTokens.bd3 : BbTokens.bd2,
                    ),
                    boxShadow: current
                        ? <BoxShadow>[
                            BoxShadow(
                              color: BbTokens.primaryGold.withValues(
                                alpha: 0.48,
                              ),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  child: locked
                      ? const Icon(
                          Icons.lock_rounded,
                          color: BbTokens.textMuted,
                        )
                      : Text(
                          '${arena.id}',
                          style: BbText.h2(BbTokens.textPrimary),
                        ),
                ),
                const SizedBox(height: BbTokens.sp1),
                SizedBox(
                  height: 24,
                  child: skipped
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.fast_forward_rounded,
                                size: 14,
                                color: BbTokens.textMuted,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                t.arenaSkippedBadge.toUpperCase(),
                                style: BbText.tiny(BbTokens.textMuted),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          locked ? '—' : '${'★' * stars}${'☆' * (3 - stars)}',
                          maxLines: 1,
                          style: BbText.small(
                            stars > 0
                                ? BbTokens.primaryGold
                                : BbTokens.textMuted,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
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

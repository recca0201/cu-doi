import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../domain/chapters.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../sim/geometry.dart';
import '../../sim/shot_runner.dart';
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
    final double detailHeight = 202 + math.max(0, textScale - 1) * 72;

    return Scaffold(
      backgroundColor: BbTokens.nightIndigo,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: BbStarfield(opacity: .82)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -.45),
                  radius: 1.1,
                  colors: <Color>[
                    const Color(0xFF6D39D8).withValues(alpha: .22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: <Widget>[
                    _MapAppBar(progress: progress),
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
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
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
                                final ArenaSpec arena = section.arenas[index];
                                return _ArenaCard(
                                  key: ValueKey<String>('arena-${arena.id}'),
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
  static const String backButton = 'assets/images/ui/galaxy/back_button.png';
  static const String selectTitle = 'assets/images/ui/galaxy/select_title.png';
  static const String chapterTabSelected =
      'assets/images/ui/galaxy/chapter_tab_selected.png';
  static const String levelCardFrame =
      'assets/images/ui/galaxy/level_card_frame.png';
  static const String detailPanel = 'assets/images/ui/galaxy/detail_panel.png';
  static const String playButtonVi =
      'assets/images/ui/galaxy/play_button_vi.png';
}

class _MapSpriteButton extends StatelessWidget {
  const _MapSpriteButton({
    super.key,
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

class _MapAppBar extends StatelessWidget {
  const _MapAppBar({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations t = AppLocalizations.of(context);
    final bool isVietnamese =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'vi';
    return Container(
      key: const Key('arena-map-header'),
      height: 104,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: BbTokens.panelNavy,
        border: Border(
          bottom: BorderSide(color: BbTokens.outlineDark, width: 4),
        ),
      ),
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
            right: 0,
            top: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _ResourcePill(
                  icon: Icons.monetization_on_rounded,
                  value: '${progress.coins}',
                ),
                const SizedBox(height: 5),
                _ResourcePill(
                  icon: Icons.star_rounded,
                  value: '${progress.totalStars}/${kArenas.length * 3}',
                ),
              ],
            ),
          ),
          Positioned(
            left: 58,
            right: 118,
            child: Semantics(
              header: true,
              label: t.arenaSelectTitle,
              child: ExcludeSemantics(
                child: SizedBox(
                  key: const Key('arena-map-title'),
                  height: 68,
                  child: isVietnamese
                      ? Image.asset(
                          _MapArt.selectTitle,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        )
                      : BbGameTitle(
                          label: t.arenaSelectTitle,
                          height: 62,
                          fontSize: 48,
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

class _ResourcePill extends StatelessWidget {
  const _ResourcePill({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 104,
    height: 34,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    decoration: BoxDecoration(
      color: BbTokens.nightIndigo,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: BbTokens.secondaryBlue, width: 2),
    ),
    child: Row(
      children: <Widget>[
        Icon(icon, color: BbTokens.primaryGold, size: 20),
        const SizedBox(width: 5),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: BbText.h3(Colors.white)),
          ),
        ),
      ],
    ),
  );
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
  Widget build(BuildContext context) => Container(
    height: 70,
    padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
    color: BbTokens.nightIndigo.withValues(alpha: .96),
    child: Row(
      children: List<Widget>.generate(sections.length, (int index) {
        final ChapterSection section = sections[index];
        final bool selected = index == selectedIndex;
        final String full = chapterTitle(
          section.chapter,
          AppLocalizations.of(context),
        );
        final List<String> parts = full.split('·');
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Semantics(
              selected: selected,
              button: true,
              label: full,
              child: InkWell(
                onTap: () => onSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: BbTokens.durBase,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? null
                        : const LinearGradient(
                            colors: <Color>[
                              Color(0xFF174B8D),
                              Color(0xFF102A63),
                            ],
                          ),
                    image: selected
                        ? const DecorationImage(
                            image: AssetImage(_MapArt.chapterTabSelected),
                            fit: BoxFit.fill,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    border: selected
                        ? null
                        : Border.all(color: BbTokens.secondaryBlue, width: 2),
                    boxShadow: selected ? null : BbTokens.sticker(3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          parts.first.trim().toUpperCase(),
                          style: BbText.button(
                            selected ? BbTokens.outlineDark : Colors.white,
                          ).copyWith(fontSize: 13),
                        ),
                      ),
                      if (parts.length > 1)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            parts.last.trim(),
                            style: BbText.tiny(
                              selected
                                  ? BbTokens.outlineDark
                                  : BbTokens.textMuted,
                            ).copyWith(fontSize: 9, letterSpacing: 0),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
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
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 4),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              chapterTitle(section.chapter, AppLocalizations.of(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BbText.h3(Colors.white).copyWith(fontSize: 16),
            ),
          ),
          Text(
            AppLocalizations.of(context).chapterProgressLabel(earned, max),
            style: BbText.small(BbTokens.primaryGold),
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
    final Color outline = selected
        ? BbTokens.primaryGold
        : (locked ? BbTokens.textMuted : BbTokens.secondaryBlue);

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: !locked,
      label: '${t.arenaHeading(arena.id, arenaName)}, $stateLabel',
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: BbTokens.durBase,
            decoration: BoxDecoration(
              color: BbTokens.panelNavy,
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: const AssetImage(_MapArt.levelCardFrame),
                fit: BoxFit.fill,
                colorFilter: locked
                    ? const ColorFilter.mode(Colors.black54, BlendMode.darken)
                    : null,
              ),
              border: selected ? Border.all(color: outline, width: 3) : null,
              boxShadow: selected
                  ? <BoxShadow>[
                      BoxShadow(
                        color: BbTokens.primaryGold.withValues(alpha: .45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                      ...BbTokens.sticker(4),
                    ]
                  : BbTokens.sticker(3),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(9, 20, 9, 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _ArenaPreview(arena: arena, locked: locked),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 38,
                      child: skipped
                          ? Center(
                              child: Text(
                                t.arenaSkippedBadge.toUpperCase(),
                                style: BbText.tiny(
                                  BbTokens.textMuted,
                                ).copyWith(fontSize: 9),
                              ),
                            )
                          : Row(
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
                                  size: 22,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                Positioned(
                  top: 3,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 40,
                      alignment: Alignment.center,
                      child: Text(
                        '${arena.id}',
                        style: BbText.h2(
                          locked ? BbTokens.textMuted : Colors.white,
                        ).copyWith(fontSize: 23),
                      ),
                    ),
                  ),
                ),
                if (locked)
                  const Positioned.fill(
                    child: Center(
                      child: Icon(
                        Icons.lock_rounded,
                        size: 38,
                        color: Colors.white70,
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
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(_MapArt.detailPanel),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: BbTokens.sticker(5),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: .78,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _ArenaPreview(arena: arena, locked: onPlay == null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              t.arenaNumberLabel(arena.id),
                              style: BbText.h2(
                                Colors.white,
                              ).copyWith(fontSize: 22),
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
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BbText.h3(
                          BbTokens.primaryGold,
                        ).copyWith(fontSize: 16),
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
                            .map((TargetSpec target) => target.requiredBanks)
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
          const SizedBox(height: 7),
          if (localeCode == 'vi')
            _MapSpriteButton(
              key: const Key('selected-arena-play'),
              asset: _MapArt.playButtonVi,
              width: double.infinity,
              height: 54,
              semanticLabel: t.playCta,
              onPressed: onPlay,
            )
          else
            BbButton.primary(
              key: const Key('selected-arena-play'),
              label: t.playCta.toUpperCase(),
              icon: Icons.play_arrow_rounded,
              expand: true,
              onPressed: onPlay,
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
          child: Text(
            '$label:',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BbText.small(Colors.white).copyWith(fontSize: 11),
          ),
        ),
        const SizedBox(width: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: BbText.small(BbTokens.trajectoryCyan).copyWith(fontSize: 11),
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
        ..shader = const RadialGradient(
          center: Alignment(-.45, -.55),
          colors: <Color>[Color(0xFF321B70), Color(0xFF07102D)],
        ).createShader(Offset.zero & size),
    );
    final Paint star = Paint()..color = Colors.white.withValues(alpha: .34);
    for (int i = 0; i < 18; i++) {
      canvas.drawCircle(
        Offset(
          ((i * 43 + 9) % 181) / 181 * size.width,
          ((i * 67 + 17) % 179) / 179 * size.height,
        ),
        i % 6 == 0 ? 1.1 : .45,
        star,
      );
    }
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
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = colors[target.palette % colors.length],
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = BbTokens.outlineDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, scale),
      );
      _previewText(
        canvas,
        '${target.requiredBanks}',
        center,
        radius * 1.1,
        Colors.white,
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

void _previewText(
  Canvas canvas,
  String value,
  Offset center,
  double size,
  Color color,
) {
  final TextPainter painter = TextPainter(
    text: TextSpan(
      text: value,
      style: TextStyle(
        color: color,
        fontFamily: BbText.displayFamily,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
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

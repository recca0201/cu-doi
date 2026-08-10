import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/arena_ink.dart';
import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../core/game_audio_service.dart';
import '../../core/haptic_service.dart';
import '../../domain/economy.dart';
import '../../domain/character.dart';
import '../../domain/player_progress.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../sim/geometry.dart';
import '../../sim/hint_finder.dart';
import '../../sim/shot_runner.dart';
import '../../state/hint_controller.dart';
import '../../state/providers.dart';
import '../arena_painter.dart';
import '../character_dialogue.dart';
import '../comic_effect_controller.dart';
import '../fit.dart';
import '../widgets/bb_widgets.dart';
import '../widgets/bb_backdrop.dart';
import 'arena_map_screen.dart';
import 'how_to_play_screen.dart';

enum _Outcome { won, lost }

class _GameHudPill extends StatelessWidget {
  const _GameHudPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.center = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool center;

  @override
  Widget build(BuildContext context) => Container(
    height: 34,
    constraints: const BoxConstraints(minWidth: 68),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          ArenaInk.of(ArenaInk.panelNavy),
          ArenaInk.of(ArenaInk.bgTop),
        ],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: ArenaInk.of(ArenaInk.trajectoryCyan, 0x88),
        width: 2,
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: BbTokens.outlineDark, offset: Offset(0, 3)),
      ],
    ),
    child: Row(
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      mainAxisSize: center ? MainAxisSize.max : MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 5),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: BbText.button(Colors.white).copyWith(fontSize: 13),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ArenaBankMeter extends StatelessWidget {
  const _ArenaBankMeter({required this.label, required this.banks});

  final String label;
  final int banks;

  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[Color(0xFF234F9A), Color(0xFF0A1D4B)],
      ),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: BbTokens.primaryGold, width: 2),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: BbTokens.outlineDark, offset: Offset(0, 5)),
        BoxShadow(color: Color(0x6655C9FF), blurRadius: 7),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '×${math.min(1 + banks, kMaxMultiplier)}',
          style: BbText.h1(BbTokens.primaryGold).copyWith(
            fontSize: 30,
            shadows: const <Shadow>[
              Shadow(color: BbTokens.outlineDark, offset: Offset(0, 2)),
            ],
          ),
        ),
        Container(height: 1, color: Colors.white24),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: BbText.tiny(
            Colors.white,
          ).copyWith(fontSize: 9, letterSpacing: .4),
        ),
        Text('$banks', style: BbText.h2(Colors.white).copyWith(fontSize: 25)),
      ],
    ),
  );
}

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({required this.arenaId, this.showGuide = false, super.key});

  final int arenaId;

  /// Shows the rules overlay before the first shot. The menu passes true on a
  /// fresh install so the inversion is explained once, without needing a
  /// separate tutorial flow.
  final bool showGuide;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Captured in initState rather than read on demand. Reading a provider from
  /// dispose() is unsafe — the ref may already be torn down — and this screen
  /// needs to silence gameplay effects on the way out.
  late final GameAudioService _audio;
  late final HapticService _haptics;
  final ComicEffectController _effects = ComicEffectController();
  bool _reducedMotion = false;
  bool _paused = false;

  Duration _lastTick = Duration.zero;

  late ArenaSpec _arena;
  late List<Segment> _segments;
  late List<bool> _alive;

  int _shotsLeft = 0;
  int _score = 0;
  _Outcome? _outcome;
  bool _recorded = false;
  bool _lossRecorded = false;
  int? _dismissedAtLossCount;
  int? _loadedArenaId;
  late bool _guideVisible;
  bool _resultDialogueDismissed = false;

  ShotRunner? _runner;
  List<V2> _ghost = <V2>[];
  V2 _aim = const V2(0, -1);
  final List<Stamp> _stamps = <Stamp>[];
  double _shake = 0;

  Size _lastSize = const Size(360, 640);
  ui.Image? _launcherSprite;

  @override
  void initState() {
    super.initState();
    _guideVisible = widget.showGuide;
    _audio = ref.read(gameAudioProvider);
    _haptics = ref.read(hapticServiceProvider);
    _load(_indexOf(widget.arenaId));
    _loadLauncherSprite();
    _ticker = createTicker(_onTick)..start();
  }

  Future<void> _loadLauncherSprite() async {
    final ByteData data = await rootBundle.load(
      'assets/images/ui/karst/launcher_bronze.png',
    );
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() => _launcherSprite = frame.image);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audio.stopGameplayEffects();
    _launcherSprite?.dispose();
    super.dispose();
  }

  int _indexOf(int arenaId) {
    final int i = kArenas.indexWhere((ArenaSpec a) => a.id == arenaId);
    return i < 0 ? 0 : i;
  }

  void _load(int index) {
    final int safe = index < 0 || index >= kArenas.length ? 0 : index;
    _arena = kArenas[safe];
    if (_loadedArenaId != _arena.id) _dismissedAtLossCount = null;
    _loadedArenaId = _arena.id;
    _segments = buildSegments(_arena);
    _alive = List<bool>.filled(_arena.targets.length, true);
    _shotsLeft = _arena.shots;
    _score = 0;
    _outcome = null;
    _recorded = false;
    _lossRecorded = false;
    _resultDialogueDismissed = false;
    _runner = null;
    _ghost = <V2>[];
    _stamps.clear();
    _effects.clear();
    _aim = const V2(0, -1);
    _shake = 0;
    ref.read(hintControllerProvider.notifier).onArenaLoaded(_arena.id);
  }

  // ------------------------------------------------------------------
  // loop
  // ------------------------------------------------------------------

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final double dt = _lastTick == Duration.zero
        ? 1 / 60
        : (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;
    if (_paused) return;

    bool dirty = false;

    _effects.tick(dt);
    if (_effects.isNotEmpty) dirty = true;

    final ShotRunner? runner = _runner;
    if (runner != null) {
      if (runner.ball.alive) {
        runner.step(dt);
        _drain(runner);
      } else {
        _finishShot(runner);
      }
      dirty = true;
    }

    if (_stamps.isNotEmpty) {
      for (final Stamp s in _stamps) {
        s.age += dt;
      }
      _stamps.removeWhere((Stamp s) => s.age > 1.1);
      dirty = true;
    }

    if (_shake > 0) {
      _shake = math.max(0, _shake - dt * 4.5);
      dirty = true;
    }

    if (dirty) setState(() {});
  }

  void _drain(ShotRunner runner) {
    if (runner.pending.isEmpty) return;
    final AppLocalizations t = AppLocalizations.of(context);
    final GameAudioService audio = _audio;
    int banksAtEvent =
        runner.banks -
        runner.pending
            .where((ShotEvent e) => e.kind == ShotEventKind.bank)
            .length;

    for (final ShotEvent e in runner.pending) {
      if (e.kind == ShotEventKind.bank) banksAtEvent = e.bankCount;
      if (e.kind == ShotEventKind.broke) banksAtEvent = e.bankCount;
      _effects.onEvent(
        e,
        banksAtEvent: banksAtEvent,
        targets: _arena.targets,
        alive: _alive,
      );
      if (e.kind == ShotEventKind.bank) {
        audio.play(GameSound.wallImpact);
        _haptics.fire(HapticEvent.bank);
        if (e.bankCount == 1) {
          _stamps.add(Stamp(t.stampBank, e.pos, ArenaInk.frame));
        } else if (e.bankCount % 3 == 0) {
          final int mult = math.min(1 + e.bankCount, kMaxMultiplier);
          _stamps.add(Stamp('×$mult', e.pos, ArenaInk.frame));
        }
      } else if (e.kind == ShotEventKind.blocked) {
        // The teaching moment. A direct hit is not a near miss — it is the
        // wrong idea, and the target says so.
        audio.play(GameSound.blockedGap);
        _haptics.fire(HapticEvent.blockedShot);
        _stamps.add(Stamp(t.stampBlocked, e.pos, ArenaInk.danger));
      } else {
        audio.play(GameSound.comicImpact);
        _haptics.fire(HapticEvent.targetBroken);
        _score += e.points;
        _shake = 1;
        _stamps.add(Stamp('+${e.points}', e.pos, ArenaInk.cream, big: true));
      }
    }
    runner.pending.clear();
  }

  void _finishShot(ShotRunner runner) {
    _effects.endShot(runner.endReason);
    // Keep the dead shot's path as a faint ghost — learning a carom is far
    // easier when the line you just took is still on screen.
    _ghost = List<V2>.of(runner.trail);
    _runner = null;

    int remaining = 0;
    for (final bool a in _alive) {
      if (a) remaining++;
    }

    if (remaining == 0) {
      _outcome = _Outcome.won;
      _effects.levelEnd(runner.ball.pos);
      _haptics.fire(HapticEvent.levelEnd);
      _onWin();
    } else if (_shotsLeft <= 0) {
      _outcome = _Outcome.lost;
      if (!_lossRecorded) {
        _lossRecorded = true;
        ref.read(progressProvider.notifier).recordLoss(_arena.id);
      }
      _audio.play(GameSound.lose, scope: GameAudioScope.terminalResult);
      _haptics.fire(HapticEvent.levelEnd);
    }
  }

  void _onWin() {
    if (_recorded) return;
    _recorded = true;
    final int stars = starsFor(_arena, _score);
    _audio.play(GameSound.win, scope: GameAudioScope.terminalResult);
    if (stars >= 3) _audio.play(GameSound.politeClap);
    ref.read(progressProvider.notifier).record(_arena.id, stars, _score);
  }

  void _fire() {
    if (_guideVisible ||
        _runner != null ||
        _outcome != null ||
        _shotsLeft <= 0) {
      return;
    }
    _effects.clear();
    _shotsLeft--;
    ref.read(hintControllerProvider.notifier).clearOnShot();
    _audio.play(GameSound.shoot);
    _runner = ShotRunner(
      segments: _segments,
      targets: _arena.targets,
      alive: _alive,
      origin: kShooterOrigin,
      direction: _aim,
    );
  }

  void _aimAt(Offset local) {
    final ArenaFit fit = ArenaFit.of(_lastSize);
    _aim = clampAim(fit.toLogical(local) - kShooterOrigin);
  }

  // ------------------------------------------------------------------
  // build
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _effects.reducedMotion = _reducedMotion;
    final AppLocalizations t = AppLocalizations.of(context);
    final HintState hint = ref.watch(hintControllerProvider);
    return Scaffold(
      backgroundColor: ArenaInk.of(ArenaInk.bgTop),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _hud(t),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  _lastSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      const BbCanyonBackdrop(scrim: .46, bottomShade: .70),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (TapUpDetails d) => setState(() {
                          _aimAt(d.localPosition);
                          _fire();
                        }),
                        onPanStart: (DragStartDetails d) =>
                            setState(() => _aimAt(d.localPosition)),
                        onPanUpdate: (DragUpdateDetails d) =>
                            setState(() => _aimAt(d.localPosition)),
                        onPanEnd: (DragEndDetails d) => setState(_fire),
                        child: SizedBox.expand(
                          child: CustomPaint(painter: _painter(hint.path)),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 12,
                        child: IgnorePointer(
                          child: _ArenaBankMeter(
                            label: t.banksLabel,
                            banks: _runner?.banks ?? 0,
                          ),
                        ),
                      ),
                      if (_guideVisible) _guide(t),
                      if (_outcome != null && !_guideVisible)
                        _result(t, _outcome!),
                    ],
                  );
                },
              ),
            ),
            _footer(t, hint),
          ],
        ),
      ),
    );
  }

  ArenaPainter _painter(List<V2> hintPath) {
    final ShotRunner? runner = _runner;
    final bool inFlight = runner != null && runner.ball.alive;

    // Only recompute the aim preview while idle — it is hidden during flight and
    // is the most expensive thing on the frame.
    final List<V2> preview = (!inFlight && _outcome == null && !_guideVisible)
        ? previewPath(
            segments: _segments,
            targets: _arena.targets,
            alive: _alive,
            origin: kShooterOrigin,
            direction: _aim,
          )
        : const <V2>[];

    return ArenaPainter(
      arena: _arena,
      alive: _alive,
      aimDirection: _aim,
      previewPoints: preview,
      showPreview: _shotsLeft > 0,
      trail: runner?.trail ?? const <V2>[],
      ghostTrail: _ghost,
      hintPath: hintPath,
      ballPos: inFlight ? runner.ball.pos : null,
      currentBanks: runner?.banks ?? 0,
      shotInFlight: inFlight,
      stamps: _stamps,
      shake: _reducedMotion ? 0 : _shake,
      effects: _effects.elements,
      reducedMotion: _reducedMotion,
      illustratedBackdrop: true,
      launcherSprite: _launcherSprite,
    );
  }

  Widget _hud(AppLocalizations t) {
    final String code = Localizations.localeOf(context).languageCode;
    final int banks = _runner?.banks ?? 0;
    final PlayerProgress progress = ref.watch(progressProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            ArenaInk.of(ArenaInk.bgTop),
            ArenaInk.of(ArenaInk.panelNavy),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: ArenaInk.of(ArenaInk.trajectoryCyan, 0x55),
            width: 2,
          ),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black54, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              BbIconButton(
                icon: Icons.arrow_back_rounded,
                variant: BbVariant.secondary,
                semanticLabel: t.menuCta,
                diameter: 46,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  children: <Widget>[
                    BbGameTitle(
                      key: const Key('game-stage-title'),
                      label: t.arenaNumberLabel(_arena.id),
                      height: 36,
                      fontSize: 27,
                      tilt: -.01,
                    ),
                    Text(
                      forLocale(code, _arena.name, _arena.nameEn),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BbText.small(
                        BbTokens.textMuted,
                      ).copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              BbIconButton(
                icon: Icons.pause_rounded,
                variant: BbVariant.secondary,
                semanticLabel: t.pauseTitle,
                diameter: 46,
                onPressed: () => _showPause(t),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: <Widget>[
              _GameHudPill(
                icon: Icons.monetization_on_rounded,
                iconColor: BbTokens.primaryGold,
                label: '${progress.coins}',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GameHudPill(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: BbTokens.trajectoryCyan,
                  label: '$_score ${t.scoreLabel}',
                  center: true,
                ),
              ),
              const SizedBox(width: 8),
              _GameHudPill(
                icon: Icons.radio_button_checked_rounded,
                iconColor: BbTokens.dangerRed,
                label: t.shotsLeft(_shotsLeft),
              ),
              if (banks > 0) ...<Widget>[
                const SizedBox(width: 8),
                _GameHudPill(
                  icon: Icons.bolt_rounded,
                  iconColor: BbTokens.primaryGold,
                  label: t.multiplier(math.min(1 + banks, kMaxMultiplier)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(AppLocalizations t, HintState hint) {
    final String code = Localizations.localeOf(context).languageCode;
    final PlayerProgress progress = ref.watch(progressProvider);
    final int missing = progress.coins < kHintCost
        ? kHintCost - progress.coins
        : 0;
    final bool enabled =
        progress.canAfford(kHintCost) &&
        hint.status != HintStatus.computing &&
        hint.status != HintStatus.shown &&
        _runner == null &&
        _outcome == null &&
        !_guideVisible;
    final String statusText = switch (hint.status) {
      HintStatus.computing => t.hintComputing,
      HintStatus.unavailable => t.hintUnavailable,
      HintStatus.failed => t.hintFailed,
      HintStatus.insufficientCoins => t.hintInsufficientCoins(missing),
      HintStatus.shown => t.hintShownAnnouncement(hint.targetsDestroyed),
      HintStatus.idle => '',
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 10),
      decoration: BoxDecoration(
        color: ArenaInk.of(ArenaInk.panelNavy),
        border: Border(
          top: BorderSide(color: ArenaInk.of(ArenaInk.danger, 0x99), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: BbTokens.dangerRed,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                t.floorDangerLabel,
                style: BbText.button(BbTokens.dangerRed).copyWith(fontSize: 14),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.warning_amber_rounded,
                color: BbTokens.dangerRed,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  forLocale(code, _arena.hint, _arena.hintEn),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BbText.small(
                    ArenaInk.of(ArenaInk.cream, 0xCC),
                  ).copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              BbButton.primary(
                key: const Key('hint-button'),
                label:
                    (missing > 0
                            ? t.hintInsufficientCoins(missing)
                            : t.hintCostBadge(kHintCost))
                        .toUpperCase(),
                size: BbSize.md,
                icon: Icons.route_rounded,
                onPressed: enabled ? _requestHint : null,
              ),
            ],
          ),
          if (statusText.isNotEmpty) ...<Widget>[
            const SizedBox(height: BbTokens.sp2),
            Semantics(
              liveRegion: true,
              label: statusText,
              child: Text(
                statusText,
                textAlign: TextAlign.center,
                style: BbText.tiny(ArenaInk.of(ArenaInk.cream)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPause(AppLocalizations t) async {
    if (_paused || _outcome != null) return;
    setState(() => _paused = true);
    final bool? leave = await showBbDialog<bool>(
      context,
      (BuildContext dialogContext) => BbDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.pause_circle_filled_rounded,
              size: 72,
              color: ArenaInk.of(ArenaInk.trajectoryCyan),
            ),
            const SizedBox(height: BbTokens.sp3),
            BbGameTitle(label: t.pauseTitle, height: 52, fontSize: 38),
            const SizedBox(height: BbTokens.sp5),
            BbButton.primary(
              label: t.resumeCta,
              icon: Icons.play_arrow_rounded,
              expand: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            const SizedBox(height: BbTokens.sp3),
            BbButton.light(
              label: t.menuCta,
              icon: Icons.home_rounded,
              expand: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ),
      dismissible: false,
    );
    if (!mounted) return;
    setState(() => _paused = false);
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _requestHint() {
    ref
        .read(hintControllerProvider.notifier)
        .request(
          ArenaSnapshot(
            segments: _segments,
            targets: _arena.targets,
            alive: _alive,
            origin: kShooterOrigin,
            arenaId: _arena.id,
          ),
        );
  }

  Widget _guide(AppLocalizations t) {
    return HowToPlayPanel(
      showDialogue: true,
      onDismiss: _dismissGuide,
      onDontShowAgain: _dismissGuide,
    );
  }

  void _dismissGuide() {
    ref.read(dialogueSeenProvider.notifier).markSeen(DialogueId.intro);
    if (mounted) setState(() => _guideVisible = false);
  }

  Widget _result(AppLocalizations t, _Outcome outcome) {
    final bool won = outcome == _Outcome.won;
    final int stars = won ? starsFor(_arena, _score) : 0;
    final int index = _indexOf(_arena.id);
    final bool hasNext = index + 1 < kArenas.length;
    final PlayerProgress progress = ref.watch(progressProvider);
    final int losses = progress.lossesFor(_arena.id);
    final bool maySkip =
        !won &&
        losses >= kSkipOfferAfterLosses &&
        !progress.isCompleted(_arena.id) &&
        !progress.isSkipped(_arena.id);
    final bool showReminder =
        !won &&
        losses >= kHintReminderAfterLosses &&
        _dismissedAtLossCount != losses;
    final bool canSkip = progress.canAfford(kSkipCost);
    final bool crowded = losses >= kSkipOfferAfterLosses;
    final DialogueId resultDialogue = won
        ? (hasNext ? DialogueId.levelWin : DialogueId.finalVictory)
        : (crowded ? DialogueId.levelLoseShort : DialogueId.levelLose);

    return Container(
      color: ArenaInk.of(ArenaInk.bgTop, 0xE6),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BbTokens.sp6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BbGameTitle(
                  key: Key(won ? 'result-win-title' : 'result-lose-title'),
                  label: won ? t.resultWin : t.resultLose,
                  tone: won ? BbTitleTone.victory : BbTitleTone.danger,
                  height: won ? 82 : 72,
                  fontSize: won ? 56 : 48,
                ),
                if (won) ...<Widget>[
                  const SizedBox(height: BbTokens.sp4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      3,
                      (int i) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: BbTokens.sp1,
                        ),
                        child: Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: i == 1 ? 72 : 58,
                          color: i < stars
                              ? BbTokens.primaryGold
                              : BbTokens.textMuted,
                          shadows: const <Shadow>[
                            Shadow(
                              color: BbTokens.outlineDark,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: BbTokens.sp3),
                if (won)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(BbTokens.sp4),
                    decoration: BoxDecoration(
                      color: BbTokens.panelNavy,
                      borderRadius: BorderRadius.circular(BbTokens.rLg),
                      border: Border.all(
                        color: BbTokens.textMuted.withValues(alpha: .45),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      t.resultScore(_score),
                      textAlign: TextAlign.center,
                      style: BbText.score(BbTokens.textPrimary),
                    ),
                  )
                else
                  Text(
                    t.resultScore(_score),
                    style: BbText.h3(BbTokens.trajectoryCyan),
                  ),
                if (!_resultDialogueDismissed) ...<Widget>[
                  const SizedBox(height: BbTokens.sp3),
                  CharacterDialogue(
                    id: resultDialogue,
                    onDismiss: () =>
                        setState(() => _resultDialogueDismissed = true),
                  ),
                ],
                if (showReminder) ...<Widget>[
                  const SizedBox(height: BbTokens.sp3),
                  BbCard(
                    color: ArenaInk.of(ArenaInk.bgBottom),
                    padding: const EdgeInsets.all(BbTokens.sp3),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            losses >= kSkipOfferAfterLosses &&
                                    !progress.isCompleted(_arena.id)
                                ? t.stuckReminderHintAndSkip(
                                    kHintCost,
                                    kSkipCost,
                                  )
                                : t.stuckReminderHint(kHintCost),
                            style: BbText.small(ArenaInk.of(ArenaInk.cream)),
                          ),
                        ),
                        BbIconButton(
                          icon: Icons.close_rounded,
                          diameter: BbTokens.tapMin,
                          variant: BbVariant.danger,
                          semanticLabel: t.backCta,
                          onPressed: () =>
                              setState(() => _dismissedAtLossCount = losses),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: BbTokens.sp6),
                if (won && hasNext) ...<Widget>[
                  BbButton.primary(
                    label: t.nextArenaCta,
                    size: won ? BbSize.lg : BbSize.md,
                    icon: Icons.double_arrow_rounded,
                    expand: true,
                    onPressed: () => setState(() {
                      _guideVisible = false;
                      _load(index + 1);
                    }),
                  ),
                  const SizedBox(height: BbTokens.sp3),
                ] else ...<Widget>[
                  BbButton.primary(
                    label: won ? t.retryCta : t.stuckReminderRetryCta,
                    size: BbSize.lg,
                    icon: Icons.refresh_rounded,
                    expand: true,
                    onPressed: () => setState(() => _load(index)),
                  ),
                  const SizedBox(height: BbTokens.sp3),
                ],
                if (maySkip) ...<Widget>[
                  BbButton.secondary(
                    key: const Key('skip-arena-button'),
                    label: t.skipArenaLabel,
                    expand: true,
                    onPressed: canSkip ? () => _confirmSkip(t, index) : null,
                  ),
                  const SizedBox(height: BbTokens.sp2),
                  BbBadge(
                    canSkip
                        ? t.skipArenaCostBadge(kSkipCost)
                        : t.skipArenaInsufficientCoins(
                            progress.coins < kSkipCost
                                ? kSkipCost - progress.coins
                                : 0,
                          ),
                    color: ArenaInk.of(ArenaInk.bgTop),
                    fg: ArenaInk.of(ArenaInk.primaryGold),
                  ),
                  const SizedBox(height: BbTokens.sp3),
                ],
                if (won && hasNext) ...<Widget>[
                  BbButton.secondary(
                    label: t.retryCta,
                    icon: Icons.refresh_rounded,
                    expand: true,
                    onPressed: () => setState(() => _load(index)),
                  ),
                  const SizedBox(height: BbTokens.sp3),
                ],
                BbButton.light(
                  label: won ? t.arenaSelectCta : t.menuCta,
                  icon: won ? Icons.grid_view_rounded : Icons.home_rounded,
                  expand: true,
                  onPressed: won
                      ? () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => ArenaMapScreen(
                              targetArenaId: hasNext
                                  ? kArenas[index + 1].id
                                  : _arena.id,
                            ),
                          ),
                        )
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSkip(AppLocalizations t, int index) async {
    final bool? confirmed = await showBbDialog<bool>(
      context,
      (BuildContext dialogContext) => BbDialog(
        color: ArenaInk.of(ArenaInk.bgBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.skipArenaConfirmTitle,
              style: BbText.h2(ArenaInk.of(ArenaInk.cream)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BbTokens.sp3),
            Text(
              t.skipArenaConfirmBody,
              style: BbText.body(ArenaInk.of(ArenaInk.cream)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BbTokens.sp5),
            BbButton.primary(
              label: t.skipArenaConfirmCta,
              expand: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
            const SizedBox(height: BbTokens.sp3),
            BbButton.secondary(
              label: t.backCta,
              expand: true,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final SpendResult result = await ref
        .read(progressProvider.notifier)
        .skipArena(_arena.id);
    if (!mounted) return;
    switch (result) {
      case SpendResult.ok:
        final int targetArenaId = index + 1 < kArenas.length
            ? kArenas[index + 1].id
            : _arena.id;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) =>
                ArenaMapScreen(targetArenaId: targetArenaId),
          ),
        );
      case SpendResult.insufficientCoins:
        setState(() {});
      case SpendResult.writeFailed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(t.skipArenaWriteFailed)));
    }
  }
}

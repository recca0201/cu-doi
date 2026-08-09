import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/arena_ink.dart';
import '../../core/bb_theme.dart';
import '../../core/bb_tokens.dart';
import '../../core/game_audio_service.dart';
import '../../l10n/app_localizations.dart';
import '../../sim/arena.dart';
import '../../sim/arenas.dart';
import '../../sim/geometry.dart';
import '../../sim/shot_runner.dart';
import '../../state/providers.dart';
import '../arena_painter.dart';
import '../fit.dart';
import '../widgets/bb_widgets.dart';

enum _Outcome { won, lost }

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

  Duration _lastTick = Duration.zero;

  late ArenaSpec _arena;
  late List<Segment> _segments;
  late List<bool> _alive;

  int _shotsLeft = 0;
  int _score = 0;
  _Outcome? _outcome;
  bool _recorded = false;
  late bool _guideVisible;

  ShotRunner? _runner;
  List<V2> _ghost = <V2>[];
  V2 _aim = const V2(0, -1);
  final List<Stamp> _stamps = <Stamp>[];
  double _shake = 0;

  Size _lastSize = const Size(360, 640);

  @override
  void initState() {
    super.initState();
    _guideVisible = widget.showGuide;
    _audio = ref.read(gameAudioProvider);
    _load(_indexOf(widget.arenaId));
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _audio.stopGameplayEffects();
    super.dispose();
  }

  int _indexOf(int arenaId) {
    final int i = kArenas.indexWhere((ArenaSpec a) => a.id == arenaId);
    return i < 0 ? 0 : i;
  }

  void _load(int index) {
    final int safe = index < 0 || index >= kArenas.length ? 0 : index;
    _arena = kArenas[safe];
    _segments = buildSegments(_arena);
    _alive = List<bool>.filled(_arena.targets.length, true);
    _shotsLeft = _arena.shots;
    _score = 0;
    _outcome = null;
    _recorded = false;
    _runner = null;
    _ghost = <V2>[];
    _stamps.clear();
    _aim = const V2(0, -1);
    _shake = 0;
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

    bool dirty = false;

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

    for (final ShotEvent e in runner.pending) {
      if (e.kind == ShotEventKind.bank) {
        audio.play(GameSound.wallImpact);
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
        _stamps.add(Stamp(t.stampBlocked, e.pos, ArenaInk.danger));
      } else {
        audio.play(GameSound.pop);
        if (e.bankCount >= 3) audio.play(GameSound.comicImpact);
        _score += e.points;
        _shake = 1;
        _stamps.add(Stamp('+${e.points}', e.pos, ArenaInk.cream, big: true));
      }
    }
    runner.pending.clear();
  }

  void _finishShot(ShotRunner runner) {
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
      _onWin();
    } else if (_shotsLeft <= 0) {
      _outcome = _Outcome.lost;
      _audio.play(GameSound.lose, scope: GameAudioScope.terminalResult);
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
    _shotsLeft--;
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
    final AppLocalizations t = AppLocalizations.of(context);
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
                          child: CustomPaint(painter: _painter()),
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
            _footer(t),
          ],
        ),
      ),
    );
  }

  ArenaPainter _painter() {
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
      ballPos: inFlight ? runner.ball.pos : null,
      currentBanks: runner?.banks ?? 0,
      shotInFlight: inFlight,
      stamps: _stamps,
      shake: _shake,
    );
  }

  Widget _hud(AppLocalizations t) {
    final String code = Localizations.localeOf(context).languageCode;
    final int banks = _runner?.banks ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BbTokens.sp4,
        BbTokens.sp3,
        BbTokens.sp4,
        BbTokens.sp2,
      ),
      child: Row(
        children: <Widget>[
          BbIconButton(
            icon: Icons.close_rounded,
            variant: BbVariant.light,
            semanticLabel: t.menuCta,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: BbTokens.sp3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  t.arenaHeading(
                    _arena.id,
                    forLocale(code, _arena.name, _arena.nameEn),
                  ),
                  style: BbText.h3(ArenaInk.of(ArenaInk.cream)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  t.shotsLeft(_shotsLeft),
                  style: BbText.small(ArenaInk.of(ArenaInk.frame)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('$_score', style: BbText.score(ArenaInk.of(ArenaInk.cream))),
              Text(
                banks > 0
                    ? t.multiplier(math.min(1 + banks, kMaxMultiplier))
                    : t.scoreLabel,
                style: BbText.small(
                  ArenaInk.of(banks > 0 ? ArenaInk.frame : ArenaInk.cream),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(AppLocalizations t) {
    final String code = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BbTokens.sp4,
        BbTokens.sp2,
        BbTokens.sp4,
        BbTokens.sp4,
      ),
      child: Text(
        forLocale(code, _arena.hint, _arena.hintEn),
        textAlign: TextAlign.center,
        style: BbText.small(ArenaInk.of(ArenaInk.cream, 0xCC)),
      ),
    );
  }

  Widget _guide(AppLocalizations t) {
    return Container(
      color: ArenaInk.of(ArenaInk.bgTop, 0xF2),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BbTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              t.howToTitle,
              style: BbText.h1(ArenaInk.of(ArenaInk.frame)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BbTokens.sp4),
            for (final String rule in <String>[
              t.howToRule1,
              t.howToRule2,
              t.howToRule3,
              t.howToRule4,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: BbTokens.sp3),
                child: Text(
                  rule,
                  textAlign: TextAlign.center,
                  style: BbText.body(ArenaInk.of(ArenaInk.cream)),
                ),
              ),
            const SizedBox(height: BbTokens.sp4),
            BbButton.accent(
              label: t.gotItCta,
              onPressed: () => setState(() => _guideVisible = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _result(AppLocalizations t, _Outcome outcome) {
    final bool won = outcome == _Outcome.won;
    final int stars = won ? starsFor(_arena, _score) : 0;
    final int index = _indexOf(_arena.id);
    final bool hasNext = index + 1 < kArenas.length;

    return Container(
      color: ArenaInk.of(ArenaInk.bgTop, 0xE6),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(BbTokens.sp6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              won ? t.resultWin : t.resultLose,
              style: BbText.display(ArenaInk.of(ArenaInk.cream)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BbTokens.sp2),
            Text(
              t.resultScore(_score),
              style: BbText.h3(ArenaInk.of(ArenaInk.frame)),
            ),
            if (won) ...<Widget>[
              const SizedBox(height: BbTokens.sp3),
              Text(
                '${'★' * stars}${'☆' * (3 - stars)}',
                style: BbText.display(ArenaInk.of(ArenaInk.frame)),
              ),
            ],
            const SizedBox(height: BbTokens.sp6),
            BbButton.primary(
              label: t.retryCta,
              expand: true,
              onPressed: () => setState(() => _load(index)),
            ),
            const SizedBox(height: BbTokens.sp3),
            if (won && hasNext)
              BbButton.accent(
                label: t.nextArenaCta,
                expand: true,
                onPressed: () => setState(() {
                  _guideVisible = false;
                  _load(index + 1);
                }),
              )
            else
              BbButton.light(
                label: t.menuCta,
                expand: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

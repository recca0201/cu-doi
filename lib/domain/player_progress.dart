/// Per-level best result.
class LevelResult {
  const LevelResult({
    this.stars = 0,
    this.highScore = 0,
    this.skipped = false,
    this.losses = 0,
  });
  final int stars;
  final int highScore;
  final bool skipped;
  final int losses;

  Map<String, dynamic> toJson() => {
    'stars': stars,
    'highScore': highScore,
    'skipped': skipped,
    'losses': losses,
  };
  factory LevelResult.fromJson(Map<String, dynamic> j) => LevelResult(
    stars: j['stars'] as int? ?? 0,
    highScore: j['highScore'] as int? ?? 0,
    skipped: j['skipped'] as bool? ?? false,
    losses: j['losses'] as int? ?? 0,
  );
}

/// Immutable player progress: level results, coins, and unlock derivation
/// (US-002, US-010, US-011, US-017). Persisted verbatim by the repository.
class PlayerProgress {
  const PlayerProgress({this.results = const {}, this.coins = 0});

  final Map<int, LevelResult> results;
  final int coins;

  int get totalStars => results.values.fold(0, (sum, r) => sum + r.stars);

  /// Best single-level score — the "Điểm cao nhất" line on the menu and the
  /// `users/{uid}.bestScore` field in the Firestore schema (GAME_SPEC §1).
  int get bestScore =>
      results.values.fold(0, (mx, r) => r.highScore > mx ? r.highScore : mx);

  int get completedMax => results.entries
      .where((e) => e.value.stars >= 1 || e.value.skipped)
      .fold(0, (mx, e) => e.key > mx ? e.key : mx);

  /// Highest unlocked level id — the next after the furthest completed.
  int get unlockedMax => completedMax + 1;

  bool isUnlocked(int levelId) => levelId >= 1 && levelId <= unlockedMax;
  int starsFor(int levelId) => results[levelId]?.stars ?? 0;
  int highScoreFor(int levelId) => results[levelId]?.highScore ?? 0;
  bool isCompleted(int levelId) => starsFor(levelId) >= 1;
  bool isSkipped(int levelId) => results[levelId]?.skipped ?? false;
  int lossesFor(int levelId) => results[levelId]?.losses ?? 0;
  bool canAfford(int amount) => amount >= 0 && coins >= amount;

  PlayerProgress withCoinsSpent(int amount) => PlayerProgress(
    results: results,
    coins: (coins - (amount < 0 ? 0 : amount)).clamp(0, 1 << 30),
  );

  PlayerProgress withSkipped(int levelId) {
    final LevelResult prev = results[levelId] ?? const LevelResult();
    final next = Map<int, LevelResult>.from(results)
      ..[levelId] = LevelResult(
        stars: prev.stars,
        highScore: prev.highScore,
        skipped: true,
      );
    return PlayerProgress(results: next, coins: coins);
  }

  PlayerProgress withLoss(int levelId) {
    final LevelResult prev = results[levelId] ?? const LevelResult();
    final next = Map<int, LevelResult>.from(results)
      ..[levelId] = LevelResult(
        stars: prev.stars,
        highScore: prev.highScore,
        skipped: prev.skipped,
        losses: prev.losses + 1,
      );
    return PlayerProgress(results: next, coins: coins);
  }

  /// Record a finished level. Keeps the best stars/score; awards coins only for
  /// net new score progress (coins are accumulated display points in MVP).
  PlayerProgress withResult(int levelId, int stars, int score) {
    final prev = results[levelId];
    final bestStars = prev == null
        ? stars
        : (stars > prev.stars ? stars : prev.stars);
    final bestScore = prev == null
        ? score
        : (score > prev.highScore ? score : prev.highScore);
    final earned = prev == null
        ? score ~/ 10
        : ((score - prev.highScore) ~/ 10).clamp(0, 1 << 30);
    final next = Map<int, LevelResult>.from(results)
      ..[levelId] = LevelResult(stars: bestStars, highScore: bestScore);
    return PlayerProgress(results: next, coins: coins + earned);
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'results': results.map((k, v) => MapEntry(k.toString(), v.toJson())),
  };

  factory PlayerProgress.fromJson(Map<String, dynamic> j) {
    final raw = (j['results'] as Map<String, dynamic>? ?? {});
    return PlayerProgress(
      coins: j['coins'] as int? ?? 0,
      results: raw.map(
        (k, v) => MapEntry(
          int.parse(k),
          LevelResult.fromJson(v as Map<String, dynamic>),
        ),
      ),
    );
  }

  /// Deterministic account merge. Balances are deliberately max, never sum.
  static PlayerProgress merge(PlayerProgress a, PlayerProgress b) {
    final Map<int, LevelResult> merged = <int, LevelResult>{};
    for (var id = 1; id <= 20; id++) {
      final x = a.results[id] ?? const LevelResult();
      final y = b.results[id] ?? const LevelResult();
      final stars = x.stars > y.stars ? x.stars : y.stars;
      final score = x.highScore > y.highScore ? x.highScore : y.highScore;
      final losses = x.losses > y.losses ? x.losses : y.losses;
      final skipped = stars == 0 && (x.skipped || y.skipped);
      if (stars != 0 || score != 0 || losses != 0 || skipped) {
        merged[id] = LevelResult(
          stars: stars,
          highScore: score,
          skipped: skipped,
          losses: losses,
        );
      }
    }
    return PlayerProgress(
      results: merged,
      coins: (a.coins > b.coins ? a.coins : b.coins).clamp(0, 0x7fffffff),
    );
  }
}

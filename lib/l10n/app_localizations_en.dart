// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wall Ricochet Game';

  @override
  String get menuTagline => 'Straight shots don\'t count. Bank it.';

  @override
  String get playCta => 'Play';

  @override
  String get arenaSelectCta => 'Pick a stage';

  @override
  String get settingsCta => 'Settings';

  @override
  String get howToCta => 'How to play';

  @override
  String get bestScoreLabel => 'Best score';

  @override
  String get coinsLabel => 'Coins';

  @override
  String get floorDangerLabel => 'DROP OUT = SHOT LOST!';

  @override
  String get banksLabel => 'BANK COUNT';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get resumeCta => 'Resume';

  @override
  String arenaNumberLabel(int id) {
    return 'STAGE $id';
  }

  @override
  String arenaHeading(int id, String name) {
    return 'Stage $id · $name';
  }

  @override
  String shotsLeft(int count) {
    return '$count shots left';
  }

  @override
  String get scoreLabel => 'points';

  @override
  String multiplier(int value) {
    return 'BANK ×$value';
  }

  @override
  String get stampBank => 'BANK!';

  @override
  String get stampBlocked => 'Straight on, really?';

  @override
  String get resultWin => 'Cleared!';

  @override
  String get resultLose => 'Out of shots';

  @override
  String resultScore(int score) {
    return '$score points';
  }

  @override
  String get retryCta => 'Retry';

  @override
  String get nextArenaCta => 'Next stage';

  @override
  String get menuCta => 'Menu';

  @override
  String get backCta => 'Back';

  @override
  String get gotItCta => 'Got it — let\'s shoot!';

  @override
  String get arenaSelectTitle => 'Pick a stage';

  @override
  String get arenaLocked => 'Locked';

  @override
  String arenaStars(int earned, int total) {
    return '$earned/$total stars';
  }

  @override
  String get arenaLockedHint => 'Finish the stage before this one first!';

  @override
  String get arenaTargetsLabel => 'Targets';

  @override
  String get arenaBankRequirementsLabel => 'Bank requirements';

  @override
  String get arenaShotsLabel => 'Shots';

  @override
  String get arenaStarThresholdsLabel => 'Star targets';

  @override
  String get howToTitle => 'How to play';

  @override
  String get howToAimTitle => 'Aim and shoot';

  @override
  String get howToAimBody => 'Drag to aim, then release to shoot.';

  @override
  String get howToBounceTitle => 'Build up banks';

  @override
  String get howToBounceBody =>
      'The ball banks off walls, blocks, and diagonal deflectors.';

  @override
  String get howToDirectTitle => 'Direct hits don\'t count';

  @override
  String get howToDirectBody =>
      'A target only breaks after the ball has banked enough times.';

  @override
  String get howToScoreTitle => 'More banks, more points';

  @override
  String get howToScoreBody => 'Points earned = 100 × (1 + bank count).';

  @override
  String get howToFloorTitle => 'The floor is open';

  @override
  String get howToFloorBody =>
      'There is no bottom wall. A ball that drops out costs the shot.';

  @override
  String get howToTargetNote =>
      'The number on a target is the minimum bank count it needs.';

  @override
  String get dontShowAgainCta => 'Don\'t show again';

  @override
  String get howToRule1 =>
      'A direct hit destroys NOTHING. The number on each target is how many wall banks your shot needs first.';

  @override
  String get howToRule2 =>
      'The ball does not stop on contact — it keeps ricocheting. One shot can take several targets.';

  @override
  String get howToRule3 =>
      'More banks, bigger multiplier. But the floor is not a wall: a ball that drops out is gone.';

  @override
  String get howToRule4 =>
      'While the ball is flying, any target that lights up is one you can now break.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get soundLabel => 'Sound';

  @override
  String get musicLabel => 'Music';

  @override
  String get hapticsLabel => 'Haptics';

  @override
  String get languageLabel => 'Language';

  @override
  String get resetProgressCta => 'Reset progress';

  @override
  String get resetProgressDone => 'Progress cleared.';

  @override
  String get hintButtonLabel => 'Ricochet hint';

  @override
  String hintCostBadge(int cost) {
    return '$cost coins';
  }

  @override
  String hintInsufficientCoins(int missing) {
    return '$missing coins short';
  }

  @override
  String get hintUnavailable =>
      'No useful hint was found for the arena right now.';

  @override
  String get hintComputing => 'Finding a ricochet…';

  @override
  String get hintFailed =>
      'The hint could not be calculated or saved. Your coins are unchanged.';

  @override
  String hintShownAnnouncement(int count) {
    return 'Hint path shown for $count target(s).';
  }

  @override
  String get skipArenaLabel => 'Skip stage';

  @override
  String skipArenaCostBadge(int cost) {
    return '$cost coins';
  }

  @override
  String skipArenaInsufficientCoins(int missing) {
    return '$missing more coins needed to skip';
  }

  @override
  String get skipArenaConfirmTitle => 'Skip this stage?';

  @override
  String get skipArenaConfirmBody =>
      'Spend 150 coins to unlock the next stage. You can replay this one later to earn its stars.';

  @override
  String get skipArenaConfirmCta => 'Spend coins and skip';

  @override
  String get skipArenaWriteFailed =>
      'Progress could not be saved. No coins were spent.';

  @override
  String get arenaSkippedBadge => 'Skipped';

  @override
  String stuckReminderHint(int cost) {
    return 'Stuck? Reveal a hint path for $cost coins.';
  }

  @override
  String stuckReminderHintAndSkip(int hintCost, int skipCost) {
    return 'You can reveal a hint ($hintCost coins) or skip the stage ($skipCost coins).';
  }

  @override
  String get stuckReminderRetryCta => 'Try again';

  @override
  String get characterName => 'Doi';

  @override
  String get chapter1Title => 'Chapter 1 · Learn the bank';

  @override
  String get chapter2Title => 'Chapter 2 · Shelves and pockets';

  @override
  String get chapter3Title => 'Chapter 3 · Zig-zag';

  @override
  String get chapter4Title => 'Chapter 4 · Diagonal obstacles';

  @override
  String get chapterOtherTitle => 'Other stages';

  @override
  String chapterProgressLabel(int earned, int max) {
    return '$earned/$max stars';
  }

  @override
  String get currentLevelBadge => 'Current';

  @override
  String get dialogueIntro =>
      'I\'m Doi. Straight shots only make them laugh—bank the ball enough times, then come back for them!';

  @override
  String get dialogueWin =>
      'That was a beautiful bank! Keep that rhythm going.';

  @override
  String get dialogueLose =>
      'The line was just off. Read the last trail, change the angle a little, and try again.';

  @override
  String get dialogueLoseShort => 'Just one angle off—try again!';

  @override
  String get dialogueFinalVictory =>
      'All twenty arenas have yielded. The ricochet master title is yours!';
}

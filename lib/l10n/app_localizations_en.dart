// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bắn Bừa';

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
  String get howToTitle => 'How to play';

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
  String get languageLabel => 'Language';

  @override
  String get resetProgressCta => 'Reset progress';

  @override
  String get resetProgressDone => 'Progress cleared.';
}

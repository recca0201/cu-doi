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
  String rewardedAdCta(int reward) {
    return 'Watch ad · +$reward coins';
  }

  @override
  String get rewardedAdLoading => 'Loading ad…';

  @override
  String rewardedAdEarned(int reward) {
    return 'You earned $reward coins for a hint.';
  }

  @override
  String get rewardedAdDismissed => 'Finish the ad to earn coins.';

  @override
  String get rewardedAdUnavailable =>
      'No ad is available right now. Try again later.';

  @override
  String get rewardedAdSaveFailed =>
      'The reward could not be saved. Please try again.';

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

  @override
  String get profileTitle => 'Player profile';

  @override
  String get defaultPlayerName => 'Player';

  @override
  String get changeAvatarCta => 'Change avatar';

  @override
  String get editNameCta => 'Edit name';

  @override
  String get saveCta => 'Save';

  @override
  String get cancelCta => 'Cancel';

  @override
  String get invalidNameError => 'Enter a name of 1–20 visible characters.';

  @override
  String get guestStatus => 'Playing as guest';

  @override
  String get profileStars => 'stars';

  @override
  String get profileCompleted => 'completed';

  @override
  String get profileEncouragement => 'Your first clever bank is waiting.';

  @override
  String profileChapter(int number) {
    return 'Chapter $number';
  }

  @override
  String get accountTitle => 'Protect your progress';

  @override
  String get guestAccountBody =>
      'Sign in optionally to sync this profile across devices.';

  @override
  String get signInGoogleCta => 'Continue with Google';

  @override
  String get signInAppleCta => 'Continue with Apple';

  @override
  String get signInProgress => 'Opening the sign-in window…';

  @override
  String get signInFailedMessage =>
      'Sign-in failed. Check the Google account on this device and try again.';

  @override
  String get choosePlayerNameTitle => 'In-game name';

  @override
  String choosePlayerNameBody(String name) {
    return 'Use “$name” from your Google account, or choose a different in-game name?';
  }

  @override
  String get choosePlayerNameUseCta => 'Use Google name';

  @override
  String get choosePlayerNameCustomCta => 'Choose another name';

  @override
  String get providerConfigRequired =>
      'Sign-in will be available after release provider configuration.';

  @override
  String get avatarPresetsTitle => 'Choose a preset';

  @override
  String get devicePhotoCta => 'Photo from device';

  @override
  String get avatarPrivacyCopy =>
      'The system picker is opened only to choose and sync your avatar.';

  @override
  String get avatarInvalidError =>
      'That image could not be used. Please choose another.';

  @override
  String get openProfileCta => 'Open player profile';

  @override
  String get badgesTitle => 'Badges';

  @override
  String get badgeUnlocked => 'Unlocked';

  @override
  String get badgeLocked => 'In progress';

  @override
  String get signOutCta => 'Sign out';

  @override
  String get deleteAccountCta => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete this account?';

  @override
  String get deleteAccountBody =>
      'Cloud data and sign-in access will be deleted. A local guest copy of your progress is kept.';

  @override
  String get confirmDeleteCta => 'Confirm deletion';

  @override
  String get accountPending => 'Account deletion is in progress';

  @override
  String get accountRecovery =>
      'Provider confirmation is needed to continue deletion';

  @override
  String get accountDeleted => 'Account deletion completed';

  @override
  String get syncPending => 'Waiting to sync';

  @override
  String get signedInStatus => 'Signed in';

  @override
  String get signedInResetGuard =>
      'Sign out before resetting local progress so cloud progress cannot restore it.';

  @override
  String get signInReminderBody =>
      'Protect this progress and restore it on another device.';

  @override
  String get signInReminderCta => 'Open sign-in options';

  @override
  String get leaderboardEntryCta => 'Ranks';

  @override
  String leaderboardEntrySemantic(int arenaId) {
    return 'View leaderboard for Level $arenaId';
  }

  @override
  String leaderboardWinEntrySemantic(int arenaId) {
    return 'View leaderboard for completed Level $arenaId';
  }

  @override
  String get leaderboardTitle => 'LEADERBOARD';

  @override
  String leaderboardLevel(int arenaId, String arenaName) {
    return 'Level $arenaId · $arenaName';
  }

  @override
  String get leaderboardGlobal => 'Global';

  @override
  String get leaderboardFriends => 'Friends';

  @override
  String get leaderboardAllTime => 'All time';

  @override
  String get leaderboardYou => 'You';

  @override
  String get leaderboardOutsideTop100 => 'You are outside the top 100';

  @override
  String get leaderboardSelected => 'selected';

  @override
  String get leaderboardNotSelected => 'not selected';

  @override
  String leaderboardScopeAnnouncement(String scope) {
    return '$scope leaderboard selected';
  }

  @override
  String leaderboardLoadedAnnouncement(String scope, int arenaId) {
    return '$scope leaderboard loaded for Level $arenaId';
  }

  @override
  String get leaderboardTopThreeLabel => 'Top three players';

  @override
  String leaderboardListFromRankLabel(int rank) {
    return 'Leaderboard entries from rank $rank';
  }

  @override
  String leaderboardRowSemantics(int rank, String playerName, String score) {
    return 'Rank $rank, $playerName, $score points';
  }

  @override
  String get leaderboardCurrentPlayerSuffix => 'current player';

  @override
  String leaderboardLoadingAnnouncement(int arenaId) {
    return 'Loading leaderboard for Level $arenaId';
  }

  @override
  String get leaderboardLoadingTitle => 'Loading leaderboard…';

  @override
  String get leaderboardLoadingBadge => 'Loading';

  @override
  String leaderboardEmptyTitle(int arenaId) {
    return 'No scores for Level $arenaId yet';
  }

  @override
  String leaderboardEmptyMessage(String scope) {
    return 'Be the first player on the $scope leaderboard.';
  }

  @override
  String get leaderboardServiceErrorTitle => 'Could not load the leaderboard';

  @override
  String get leaderboardServiceErrorMessage =>
      'Game Center or Google Play Games is not responding right now.';

  @override
  String get leaderboardServiceErrorBadge => 'Service error';

  @override
  String get leaderboardRetryCta => 'Try again';

  @override
  String get leaderboardStaleTitle => 'Data may be out of date';

  @override
  String leaderboardStaleMessage(String scope, int arenaId) {
    return 'Showing the most recently saved $scope leaderboard for Level $arenaId.';
  }

  @override
  String get leaderboardOfflineBadge => 'Offline';

  @override
  String get leaderboardOfflineQueueMessage =>
      'No connection · Pending scores stay on this device';

  @override
  String get leaderboardOfflineEmptyTitle => 'No offline data';

  @override
  String leaderboardOfflineEmptyMessage(int arenaId, String scope) {
    return 'There is no matching saved leaderboard for Level $arenaId · $scope.';
  }

  @override
  String get leaderboardFriendsUnavailableTitle =>
      'Friends leaderboard unavailable';

  @override
  String get leaderboardFriendsUnavailableMessage =>
      'The friends list is unavailable because of privacy, account restrictions, or platform settings.';

  @override
  String get leaderboardViewGlobalCta => 'View Global';

  @override
  String get leaderboardAuthTitle => 'Connect the leaderboard?';

  @override
  String get leaderboardAuthDescription =>
      'Connect Game Center or Google Play Games to view leaderboards and submit records. You can still play completely offline.';

  @override
  String get leaderboardAuthConnectCta => 'Connect';

  @override
  String get leaderboardAuthLaterCta => 'Later';

  @override
  String get leaderboardAuthPromptMessage =>
      'Your local score, stars, coins, and progress stay on this device if you connect later.';

  @override
  String get leaderboardSubmissionTitle => 'Score submission';

  @override
  String get leaderboardSubmissionSent => 'Sent';

  @override
  String get leaderboardSubmissionSentMessage =>
      'The platform accepted this record.';

  @override
  String get leaderboardSubmissionPending => 'Pending';

  @override
  String get leaderboardSubmissionPendingMessage =>
      'It will be sent automatically when a connection is available.';

  @override
  String get leaderboardSubmissionFailed => 'Could not submit';

  @override
  String get leaderboardSubmissionNotQueued => 'Not submitted';

  @override
  String get leaderboardSubmissionNotQueuedMessage =>
      'This result was not a new saved record, so it was not submitted.';

  @override
  String get leaderboardSubmissionPersistFailedMessage =>
      'The result or retry queue could not be saved on this device, so the platform has not accepted it.';

  @override
  String get leaderboardSubmissionDisconnected => 'Not connected';

  @override
  String get leaderboardSubmissionDisconnectedMessage =>
      'Connect explicitly before this score can be submitted.';

  @override
  String get leaderboardSubmitScoreCta => 'Submit score';

  @override
  String get leaderboardReconnectCta => 'Reconnect';

  @override
  String get leaderboardRetrySubmissionCta => 'Submit again';

  @override
  String get leaderboardReasonUnsupported =>
      'This platform does not support score submission.';

  @override
  String get leaderboardReasonRestricted =>
      'This platform account is restricted from submitting scores.';

  @override
  String get leaderboardReasonRejected =>
      'The platform did not accept this score.';

  @override
  String get leaderboardReasonUnknown =>
      'The platform could not accept this score. Your local record is safe.';

  @override
  String leaderboardAchievedScore(String score) {
    return 'Achieved score: $score';
  }
}

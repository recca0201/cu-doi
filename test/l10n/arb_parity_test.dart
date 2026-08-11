import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Vietnamese and English ARB files have identical message keys', () {
    Set<String> keys(String path) =>
        (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>).keys
            .where((String key) => !key.startsWith('@'))
            .toSet();

    final Set<String> english = keys('lib/l10n/app_en.arb');
    final Set<String> vietnamese = keys('lib/l10n/app_vi.arb');
    expect(english, vietnamese);
    expect(
      english,
      containsAll(<String>[
        'characterName',
        'chapter1Title',
        'chapter2Title',
        'chapter3Title',
        'chapter4Title',
        'chapterOtherTitle',
        'chapterProgressLabel',
        'currentLevelBadge',
        'dialogueIntro',
        'dialogueWin',
        'dialogueLose',
        'dialogueLoseShort',
        'dialogueFinalVictory',
        'hapticsLabel',
      ]),
    );

    const Set<String> leaderboardKeys = <String>{
      'leaderboardEntryCta',
      'leaderboardEntrySemantic',
      'leaderboardWinEntrySemantic',
      'leaderboardTitle',
      'leaderboardLevel',
      'leaderboardGlobal',
      'leaderboardFriends',
      'leaderboardAllTime',
      'leaderboardYou',
      'leaderboardOutsideTop100',
      'leaderboardSelected',
      'leaderboardNotSelected',
      'leaderboardScopeAnnouncement',
      'leaderboardLoadedAnnouncement',
      'leaderboardTopThreeLabel',
      'leaderboardListFromRankLabel',
      'leaderboardRowSemantics',
      'leaderboardCurrentPlayerSuffix',
      'leaderboardLoadingAnnouncement',
      'leaderboardLoadingTitle',
      'leaderboardLoadingBadge',
      'leaderboardEmptyTitle',
      'leaderboardEmptyMessage',
      'leaderboardServiceErrorTitle',
      'leaderboardServiceErrorMessage',
      'leaderboardServiceErrorBadge',
      'leaderboardRetryCta',
      'leaderboardStaleTitle',
      'leaderboardStaleMessage',
      'leaderboardOfflineBadge',
      'leaderboardOfflineQueueMessage',
      'leaderboardOfflineEmptyTitle',
      'leaderboardOfflineEmptyMessage',
      'leaderboardFriendsUnavailableTitle',
      'leaderboardFriendsUnavailableMessage',
      'leaderboardViewGlobalCta',
      'leaderboardAuthTitle',
      'leaderboardAuthDescription',
      'leaderboardAuthConnectCta',
      'leaderboardAuthLaterCta',
      'leaderboardAuthPromptMessage',
      'leaderboardSubmissionTitle',
      'leaderboardSubmissionSent',
      'leaderboardSubmissionSentMessage',
      'leaderboardSubmissionPending',
      'leaderboardSubmissionPendingMessage',
      'leaderboardSubmissionFailed',
      'leaderboardSubmissionDisconnected',
      'leaderboardSubmissionDisconnectedMessage',
      'leaderboardSubmitScoreCta',
      'leaderboardReconnectCta',
      'leaderboardRetrySubmissionCta',
      'leaderboardReasonUnsupported',
      'leaderboardReasonRestricted',
      'leaderboardReasonRejected',
      'leaderboardReasonUnknown',
      'leaderboardAchievedScore',
    };
    expect(english, containsAll(leaderboardKeys));

    for (final String path in <String>[
      'lib/l10n/app_en.arb',
      'lib/l10n/app_vi.arb',
    ]) {
      final Map<String, dynamic> values =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> entry in values.entries) {
        if (entry.key.startsWith('@') || entry.value is! String) continue;
        expect((entry.value as String).trim(), isNotEmpty, reason: entry.key);
        expect(
          entry.value,
          isNot(contains(RegExp(r'TODO|FIXME|placeholder'))),
          reason: entry.key,
        );
      }
    }
  });

  test('leaderboard copy is localized in both supported locales', () {
    Map<String, dynamic> arb(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

    final Map<String, dynamic> vi = arb('lib/l10n/app_vi.arb');
    final Map<String, dynamic> en = arb('lib/l10n/app_en.arb');
    const List<String> representativeKeys = <String>[
      'leaderboardEntryCta',
      'leaderboardGlobal',
      'leaderboardFriends',
      'leaderboardAllTime',
      'leaderboardLoadingTitle',
      'leaderboardEmptyTitle',
      'leaderboardServiceErrorTitle',
      'leaderboardStaleTitle',
      'leaderboardOfflineEmptyTitle',
      'leaderboardFriendsUnavailableTitle',
      'leaderboardAuthTitle',
      'leaderboardSubmissionSent',
      'leaderboardSubmissionPending',
      'leaderboardSubmissionFailed',
      'leaderboardReasonRestricted',
      'leaderboardLoadedAnnouncement',
      'leaderboardRowSemantics',
    ];

    for (final String key in representativeKeys) {
      expect(vi[key], isA<String>(), reason: 'Missing VI $key');
      expect(en[key], isA<String>(), reason: 'Missing EN $key');
      expect(vi[key], isNot(en[key]), reason: 'Unlocalized $key');
    }
    expect(vi['leaderboardAllTime'], 'Mọi thời đại');
    expect(en['leaderboardAllTime'], 'All time');
    expect(vi['leaderboardRowSemantics'], startsWith('Hạng {rank}'));
    expect(en['leaderboardRowSemantics'], startsWith('Rank {rank}'));
  });
}

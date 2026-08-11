import 'dart:io';

import 'package:ban_bua_tuong/domain/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('simulation and domain dependency boundaries remain intact', () {
    for (final file
        in Directory('lib/sim')
            .listSync(recursive: true)
            .whereType<File>()
            .where((File file) => file.path.endsWith('.dart'))) {
      final String source = file.readAsStringSync();
      expect(
        RegExp(r'''import\s+['"]package:flutter''').hasMatch(source),
        isFalse,
        reason: '${file.path} must stay usable without Flutter',
      );
      expect(
        RegExp(
          r'''import\s+['"](?:dart:(?:io|html)|package:(?:http|dio|firebase_))''',
        ).hasMatch(source),
        isFalse,
        reason: '${file.path} must not acquire a network dependency',
      );
      expect(
        source,
        isNot(anyOf(contains('GameServicesGateway'), contains('Leaderboard'))),
        reason: '${file.path} must not know about leaderboard integration',
      );
    }
    for (final file in Directory('lib/domain').listSync().whereType<File>()) {
      expect(file.readAsStringSync(), isNot(contains('/l10n/')));
    }
    final arena = File('lib/sim/arena.dart').readAsStringSync();
    expect(arena, isNot(contains('final Chapter')));
    final chapters = File('lib/domain/chapters.dart').readAsStringSync();
    expect(chapters, isNot(contains('withResult(')));
    expect(chapters, isNot(contains('withSkipped(')));
  });

  test('Firebase and platform leaderboard lifecycles remain independent', () {
    const List<String> leaderboardFiles = <String>[
      'lib/data/game_services_gateway.dart',
      'lib/data/identity_hasher.dart',
      'lib/data/leaderboard_repository.dart',
      'lib/data/local_leaderboard_store.dart',
      'lib/data/method_channel_game_services_gateway.dart',
      'lib/domain/leaderboard_models.dart',
      'lib/domain/leaderboard_score_policy.dart',
      'lib/state/leaderboard_controller.dart',
      'lib/state/leaderboard_lifecycle_coordinator.dart',
    ];
    for (final String path in leaderboardFiles) {
      final String source = File(path).readAsStringSync().toLowerCase();
      expect(
        RegExp(r'''import\s+['"][^'"]*firebase''').hasMatch(source),
        isFalse,
        reason: '$path must not use Firebase as platform identity',
      );
      expect(
        RegExp(r'''import\s+['"][^'"]*account_controller''').hasMatch(source),
        isFalse,
        reason: '$path must not consume the app-account lifecycle',
      );
    }

    const List<String> appAccountFiles = <String>[
      'lib/state/account_controller.dart',
      'lib/state/sync_controller.dart',
      'lib/data/firebase_account_repository.dart',
      'lib/data/firebase_sync_repository.dart',
    ];
    for (final String path in appAccountFiles) {
      final String source = File(path).readAsStringSync().toLowerCase();
      expect(
        RegExp(r'''import\s+['"][^'"]*leaderboard''').hasMatch(source),
        isFalse,
        reason: '$path must not mutate platform leaderboard identity',
      );
      expect(
        source,
        isNot(contains('gameservicesgateway')),
        reason: '$path must not authenticate platform game services',
      );
    }
  });

  test('iOS avatar logical timeout never frees a physical GameKit slot', () {
    final String source = File(
      'ios/Runner/GameServicesBridge.swift',
    ).readAsStringSync();
    final String loader = source.substring(
      source.indexOf('final class NativeAvatarLoader'),
      source.indexOf('private final class CallbackGate'),
    );
    final String cancelAll = loader.substring(
      loader.indexOf('func cancelAll()'),
      loader.indexOf('private func start('),
    );

    expect(loader, contains('let resultGate = CallbackGate()'));
    expect(loader, contains('let workerGate = CallbackGate()'));
    expect(cancelAll, isNot(contains('activeJobs.removeAll()')));
    expect(
      loader,
      contains(
        'self.completeLogically(job, with: .failure('
        'GameServicesNativeError.retryable))',
      ),
    );
    expect(loader, contains('job.workerGate.run'));
    expect(loader, contains('self?.releasePhysicalWorker(job)'));
  });

  test('profile feature introduces no analytics or gameplay event log', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('firebase_analytics')));
    for (final directory in <String>['lib/domain', 'lib/data', 'lib/state']) {
      for (final file in Directory(directory).listSync().whereType<File>()) {
        expect(file.readAsStringSync(), isNot(contains('eventLog')));
        expect(file.readAsStringSync(), isNot(contains('logShot')));
      }
    }
  });

  test('linear unlock rule is unchanged', () {
    const progress = PlayerProgress(
      results: <int, LevelResult>{3: LevelResult(stars: 1)},
    );
    expect(progress.isUnlocked(4), isTrue);
    expect(progress.isUnlocked(5), isFalse);
  });
}

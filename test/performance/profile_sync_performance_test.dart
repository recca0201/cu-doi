import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sync and Firebase work stay outside gameplay frame loop', () {
    final game = File('lib/ui/screens/game_screen.dart').readAsStringSync();
    final painter = File('lib/ui/arena_painter.dart').readAsStringSync();
    expect(game, isNot(contains('FirebaseFirestore')));
    expect(game, isNot(contains('FirebaseFunctions')));
    expect(painter, isNot(contains('firebase')));
    final sync = File('lib/state/sync_controller.dart').readAsStringSync();
    expect(sync, isNot(contains('Ticker')));
    expect(sync, isNot(contains('CustomPainter')));
  });
}

import 'package:ban_bua_tuong/domain/player_profile.dart';
import 'package:ban_bua_tuong/ui/widgets/player_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'interactive avatar is at least 48dp and decorative avatar adds no action',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              const PlayerAvatar(avatar: PlayerAvatarRef.preset(), size: 40),
              PlayerAvatar(
                avatar: const PlayerAvatarRef.preset(),
                size: 48,
                semanticLabel: 'Change avatar',
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.bySemanticsLabel('Change avatar')).shortestSide,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.bySemanticsLabel('Change avatar'));
      expect(taps, 1);
    },
  );
}

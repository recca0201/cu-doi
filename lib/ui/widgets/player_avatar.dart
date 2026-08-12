import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/player_profile.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.avatar,
    this.size = 72,
    this.onTap,
    this.semanticLabel,
  });
  final PlayerAvatarRef avatar;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;
  static const Map<String, String> presetAssets = {
    'pangolin-gold': 'assets/images/mascot/cu_doi_mascot_pangolin_v1.png',
    'pangolin-victory':
        'assets/images/mascot/moods/pangolin_victory.png',
    'pangolin-surprised':
        'assets/images/mascot/moods/pangolin_surprised.png',
    'pangolin-gentle-sad':
        'assets/images/mascot/moods/pangolin_gentle_sad.png',
  };
  @override
  Widget build(BuildContext context) {
    Widget image;
    if (avatar.kind == AvatarKind.custom && File(avatar.value).existsSync()) {
      image = Image.file(
        File(avatar.value),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _preset(),
      );
    } else {
      image = _preset();
    }
    final visual = Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFC94A),
        border: Border.all(color: const Color(0xFF3D210E), width: 3),
      ),
      child: ClipOval(child: image),
    );
    if (onTap == null) return ExcludeSemantics(child: visual);
    final controlSize = size < 48 ? 48.0 : size;
    return SizedBox(
      width: controlSize,
      height: controlSize,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(child: visual),
          ),
        ),
      ),
    );
  }

  Widget _preset() => Image.asset(
    presetAssets[avatar.value] ?? presetAssets[kDefaultAvatarPreset]!,
    fit: BoxFit.cover,
  );
}

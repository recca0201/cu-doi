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
    'pangolin-blue': 'assets/images/mascot/cu_doi_mascot_pangolin_v1.png',
    'pangolin-purple': 'assets/images/mascot/cu_doi_mascot_pangolin_v1.png',
    'galaxy-gold': 'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
    'galaxy-blue': 'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
    'galaxy-purple': 'assets/images/mascot/cu_doi_mascot_galaxy_v3.png',
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
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: visual,
        ),
      ),
    );
  }

  Widget _preset() => Image.asset(
    presetAssets[avatar.value] ?? presetAssets[kDefaultAvatarPreset]!,
    fit: BoxFit.cover,
  );
}

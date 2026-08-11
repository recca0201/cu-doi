import 'package:characters/characters.dart';

const int kMaxDisplayNameGraphemes = 20;
const String kDefaultAvatarPreset = 'pangolin-gold';

enum AvatarKind { preset, custom }

class PlayerAvatarRef {
  const PlayerAvatarRef.preset([this.value = kDefaultAvatarPreset])
    : kind = AvatarKind.preset;
  const PlayerAvatarRef.custom(this.value) : kind = AvatarKind.custom;

  final AvatarKind kind;
  final String value;

  Map<String, Object> toJson() => <String, Object>{
    'kind': kind.name,
    'value': value,
  };

  factory PlayerAvatarRef.fromJson(Object? raw) {
    if (raw is! Map) return const PlayerAvatarRef.preset();
    final String value = raw['value'] is String ? raw['value'] as String : '';
    if (raw['kind'] == 'custom' && value.isNotEmpty) {
      return PlayerAvatarRef.custom(value);
    }
    return PlayerAvatarRef.preset(value.isEmpty ? kDefaultAvatarPreset : value);
  }
}

class PlayerProfile {
  const PlayerProfile({
    this.customDisplayName,
    this.avatar = const PlayerAvatarRef.preset(),
  });

  final String? customDisplayName;
  final PlayerAvatarRef avatar;

  String displayName(String localizedDefault) =>
      customDisplayName ?? localizedDefault;

  static String normalizeDisplayName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? validateDisplayName(String value) {
    final String normalized = normalizeDisplayName(value);
    if (normalized.isEmpty) return 'empty';
    if (normalized.characters.length > kMaxDisplayNameGraphemes) {
      return 'tooLong';
    }
    return null;
  }

  PlayerProfile copyWith({
    String? customDisplayName,
    PlayerAvatarRef? avatar,
  }) => PlayerProfile(
    customDisplayName: customDisplayName ?? this.customDisplayName,
    avatar: avatar ?? this.avatar,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'customDisplayName': customDisplayName,
    'avatar': avatar.toJson(),
  };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    customDisplayName: json['customDisplayName'] as String?,
    avatar: PlayerAvatarRef.fromJson(json['avatar']),
  );
}

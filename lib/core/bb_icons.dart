import 'package:flutter/material.dart';

/// Icon set for the app. Uses Material Icons (bundled, build-stable) mapped to
/// the design-system's intended Phosphor glyphs — filled for status, plain for
/// chrome. Centralised so the icon source can be swapped in one place.
abstract final class BbIcons {
  static const heartFill = Icons.favorite;
  static const heartOutline = Icons.favorite_border;
  static const starFill = Icons.star_rounded;
  static const starOutline = Icons.star_border_rounded;
  static const lock = Icons.lock_rounded;
  static const crown = Icons.emoji_events_rounded;
  static const play = Icons.play_arrow_rounded;
  static const pause = Icons.pause_rounded;
  static const arrowLeft = Icons.arrow_back_rounded;
  static const arrowRight = Icons.arrow_forward_rounded;
  static const refresh = Icons.refresh_rounded;
  static const settings = Icons.settings_rounded;
  static const speaker = Icons.volume_up_rounded;
  static const speakerOff = Icons.volume_off_rounded;
  static const music = Icons.music_note_rounded;
  static const translate = Icons.translate_rounded;
  static const coin = Icons.monetization_on_rounded;
  static const shuffle = Icons.shuffle_rounded;
  static const palette = Icons.palette_rounded;
  static const expression = Icons.sentiment_very_satisfied_rounded;
  static const map = Icons.map_rounded;
  static const grid = Icons.grid_view_rounded;
  static const touch = Icons.touch_app_rounded;
}

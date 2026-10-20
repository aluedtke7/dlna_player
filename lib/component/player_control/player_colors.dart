import 'package:flutter/material.dart';

/// Colors of the PlayerWidget, derived from the theme's color scheme and the
/// theme specific player background so that light and dark themes both work.
class PlayerColors {
  final Color background;
  final Color foreground;
  final Color muted;
  final Color track;
  final Color strong;
  final Color onStrong;
  final Color soft;

  const PlayerColors({
    required this.background,
    required this.foreground,
    required this.muted,
    required this.track,
    required this.strong,
    required this.onStrong,
    required this.soft,
  });

  factory PlayerColors.of(ColorScheme cs, Color widgetBg) {
    final dark = cs.brightness == Brightness.dark;
    final background = Color.lerp(widgetBg, cs.surface, 0.4)!;
    return PlayerColors(
      background: background,
      foreground: cs.onSurface,
      muted: cs.onSurfaceVariant,
      track: cs.onSurface.withValues(alpha: dark ? 0.22 : 0.15),
      strong: dark ? cs.onSurface : cs.primary,
      onStrong: dark ? background : cs.onPrimary,
      soft: cs.onSurface.withValues(alpha: dark ? 0.16 : 0.09),
    );
  }
}

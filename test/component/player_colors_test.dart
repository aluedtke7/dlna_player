import 'package:dlna_player/component/player_control/player_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widgetBg = Color(0xFFCDE1C8);

  group('PlayerColors.of', () {
    test('light theme uses primary for the play button', () {
      final cs = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light);
      final colors = PlayerColors.of(cs, widgetBg);

      expect(colors.strong, cs.primary);
      expect(colors.onStrong, cs.onPrimary);
      expect(colors.foreground, cs.onSurface);
      expect(colors.muted, cs.onSurfaceVariant);
    });

    test('dark theme uses light foreground on the tinted background', () {
      final cs = ColorScheme.fromSeed(seedColor: Colors.cyan, brightness: Brightness.dark);
      const darkBg = Color(0xFF0B535E);
      final colors = PlayerColors.of(cs, darkBg);

      expect(colors.strong, cs.onSurface);
      expect(colors.onStrong, colors.background);
      expect(colors.background.computeLuminance(), lessThan(colors.foreground.computeLuminance()));
    });

    test('background blends the theme background towards the surface', () {
      final cs = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light);
      final colors = PlayerColors.of(cs, widgetBg);

      expect(colors.background, Color.lerp(widgetBg, cs.surface, 0.4));
    });
  });
}

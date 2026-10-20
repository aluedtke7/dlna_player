import 'package:flutter/material.dart';

/// Shared look of the tiles for servers, categories, albums and tracks.
class TileStyle {
  TileStyle._();

  static const radius = BorderRadius.all(Radius.circular(18));

  static Color background(ColorScheme cs) => cs.brightness == Brightness.dark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest;

  /// Light accent tint used for icon badges and the active track.
  static Color accentSoft(ColorScheme cs) => cs.primary.withValues(alpha: cs.brightness == Brightness.dark ? 0.16 : 0.10);

  static BoxDecoration decoration(ColorScheme cs) =>
      BoxDecoration(color: background(cs), borderRadius: radius, border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)));
}

/// Rounded square with an accent tinted background holding an icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.size = 48});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: TileStyle.accentSoft(cs), borderRadius: BorderRadius.circular(size * 0.29)),
      child: Icon(icon, size: size / 2, color: cs.primary),
    );
  }
}

/// Clickable tile with the shared decoration and ripple.
class StyledTile extends StatelessWidget {
  const StyledTile({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: TileStyle.decoration(Theme.of(context).colorScheme),
        child: InkWell(borderRadius: TileStyle.radius, onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

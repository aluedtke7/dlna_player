import 'package:flutter/material.dart';

class TrackCover extends StatelessWidget {
  final String coverUrl;
  final double size;

  const TrackCover({super.key, required this.coverUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(size >= 100 ? 14 : 10);

    Widget image = Image.network(
      coverUrl,
      key: ValueKey(coverUrl),
      height: size,
      width: size,
      fit: BoxFit.cover,
      errorBuilder:
          (context, error, stackTrace) => Image.asset('assets/images/error_album.png', height: size, width: size, fit: BoxFit.cover),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.35 : 0.18), blurRadius: size / 6, offset: Offset(0, size / 14)),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: size,
          height: size,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(begin: 0.94, end: 1.0).animate(animation);
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: scale, child: child));
            },
            child: image,
          ),
        ),
      ),
    );
  }
}

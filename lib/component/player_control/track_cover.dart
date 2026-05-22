import 'dart:io';

import 'package:flutter/material.dart';

class TrackCover extends StatelessWidget {
  final String coverUrl;

  const TrackCover({
    super.key,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    final double imageSize;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      imageSize = 150.0;
    } else {
      imageSize = 90.0;
    }

    Widget image = Image.network(
      coverUrl,
      key: ValueKey(coverUrl),
      height: imageSize,
      width: imageSize,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/images/error_album.png',
        height: imageSize,
        width: imageSize,
        fit: BoxFit.cover,
      ),
    );

    return Flexible(
      fit: FlexFit.loose,
      flex: 0,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: imageSize,
            height: imageSize,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final scale = Tween<double>(begin: 0.94, end: 1.0).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: scale, child: child),
                );
              },
              child: image,
            ),
          ),
        ),
      ),
    );
  }
}

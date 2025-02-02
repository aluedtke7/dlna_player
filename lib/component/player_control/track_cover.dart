import 'dart:io';

import 'package:flutter/cupertino.dart';

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

    return Flexible(
      fit: FlexFit.loose,
      flex: 0,
      child: SizedBox(
        width: imageSize,
        child: Image.network(
          coverUrl,
          height: imageSize,
          width: imageSize,
          alignment: Alignment.centerRight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/error_album.png',
            height: imageSize,
            width: imageSize,
            alignment: Alignment.centerRight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

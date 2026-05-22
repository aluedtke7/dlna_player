import 'package:flutter/material.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.container,
    required this.disabled,
  });

  final RawContent container;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Uri albumUri = Uri.parse(container.albumArt ?? '');

    Widget buildCover(double size) {
      Widget image = albumUri.hasScheme
          ? Image.network(
              albumUri.toString(),
              height: size,
              width: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/error_album.png',
                height: size,
                width: size,
                fit: BoxFit.cover,
              ),
            )
          : Image.asset(
              'assets/images/no_album.png',
              height: size,
              width: size,
              fit: BoxFit.cover,
            );
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: image,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (container.title.isNotEmpty)
              Text(
                container.title,
                textScaler: const TextScaler.linear(1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: disabled ? Theme.of(context).disabledColor : null,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (container.artist.isNotEmpty)
                        Text(
                          container.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: disabled ? Theme.of(context).disabledColor : null,
                          ),
                        ),
                      if (container.numTracks > 0)
                        Text(
                          i18n(context).card_tracks(container.numTracks),
                          style: TextStyle(
                            color: disabled ? Theme.of(context).disabledColor : null,
                          ),
                        ),
                    ],
                  ),
                ),
                buildCover(54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

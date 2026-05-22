import 'package:flutter/material.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';

class ContainerCard extends StatelessWidget {
  const ContainerCard({
    super.key,
    required this.container,
    required this.disabled,
  });

  final RawContent container;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Uri albumUri = Uri.parse(container.albumArt ?? '');

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      if (container.genre.isNotEmpty)
                        Text(
                          i18n(context).card_genre(container.genre),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
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
                if (albumUri.hasScheme)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      albumUri.toString(),
                      height: 54,
                      width: 54,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/error_album.png',
                        height: 54,
                        width: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

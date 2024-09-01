import 'package:flutter/material.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';

class ContainerCard extends StatelessWidget {
  const ContainerCard({
    super.key,
    required this.container,
  });

  final RawContent container;

  @override
  Widget build(BuildContext context) {
    final Uri albumUri = Uri.parse(container.albumArt ?? '');

    return Card(
      elevation: 5,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (container.title.isNotEmpty)
              Text(
                container.title,
                textScaler: const TextScaler.linear(1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    if (container.artist.isNotEmpty)
                      Text(
                        container.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (container.genre.isNotEmpty)
                      Text(
                        i18n(context).card_genre(container.genre),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (container.numTracks > 0) Text(i18n(context).card_tracks(container.numTracks)),
                  ],
                ),
                if (albumUri.hasScheme)
                  SizedBox(
                    width: 65,
                    child: Image.network(
                      albumUri.toString(),
                      height: 60,
                      width: 60,
                      alignment: Alignment.centerRight,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/error_album.png',
                        height: 60,
                        width: 60,
                        alignment: Alignment.centerRight,
                        fit: BoxFit.contain,
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

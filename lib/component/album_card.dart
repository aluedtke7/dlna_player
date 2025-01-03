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
                SizedBox(
                  width: 65,
                  child: albumUri.hasScheme
                      ? Image.network(
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
                        )
                      : Image.asset(
                          'assets/images/no_album.png',
                          height: 60,
                          width: 60,
                          alignment: Alignment.centerRight,
                          fit: BoxFit.contain,
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

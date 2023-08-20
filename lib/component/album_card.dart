import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    Key? key,
    required this.container,
  }) : super(key: key);
  final RawContent container;

  @override
  Widget build(BuildContext context) {
    final Uri albumUri = Uri.parse(container.albumArt ?? '');

    return Card(
      elevation: 5,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(8),
        child: Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (container.title.isNotEmpty)
                    Text(
                      container.title,
                      textScaleFactor: 1.1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  if (container.numTracks > 0) Text(AppLocalizations.of(context)?.card_tracks(container.numTracks) ?? ''),
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
      ),
    );
  }
}

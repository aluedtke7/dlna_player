import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';

class TrackCard extends ConsumerWidget {
  const TrackCard({
    super.key,
    required this.track,
  });

  final RawContent track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Uri albumUri = Uri.parse(track.albumArt ?? '');
    var duration = '';
    if (track.duration.isNotEmpty) {
      duration = track.duration.replaceFirst(RegExp('0:'), '');
      duration = duration.replaceFirst(RegExp(r'\.(\d+)'), '');
      // Jellyfin omits the first colon...
      var doubleZero = duration.contains(RegExp(r'00\d:'));
      if (doubleZero) {
        duration = duration.substring(1);
      }
    }
    var trDuration = '';
    if (duration.isNotEmpty) trDuration = i18n(context).card_duration(duration);

    return Card(
      elevation: 5,
      child: Container(
        width: double.maxFinite,
        margin: const EdgeInsets.all(4),
        decoration: ref.read(trackProvider).id == track.id
            ? BoxDecoration(
                image: DecorationImage(
                  image: Image.asset('assets/images/play_bg.png').image,
                  opacity: 0.5,
                ),
              )
            : null,
        child: Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    textScaler: const TextScaler.linear(1.1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (track.artist.isNotEmpty)
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (track.duration.isNotEmpty)
                    Text(trDuration),
                ],
              ),
            ),
            if (albumUri.hasScheme)
              SizedBox(
                width: 55,
                child: Image.network(
                  albumUri.toString(),
                  height: 50,
                  width: 50,
                  alignment: Alignment.centerRight,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/error_album.png',
                    height: 50,
                    width: 50,
                    alignment: Alignment.centerRight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

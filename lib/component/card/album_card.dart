import 'package:flutter/material.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';

/// Cover first album tile: square cover with title, artist and track count below.
class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.container, required this.disabled, this.isPlaying = false});

  final RawContent container;
  final bool disabled;

  /// True when the current track belongs to this album.
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Uri albumUri = Uri.parse(container.albumArt ?? '');

    final Widget image =
        albumUri.hasScheme
            ? Image.network(
              albumUri.toString(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/error_album.png', fit: BoxFit.cover),
            )
            : Image.asset('assets/images/no_album.png', fit: BoxFit.cover);

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: isPlaying ? Border.all(color: cs.primary, width: 3) : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(borderRadius: BorderRadius.circular(isPlaying ? 11 : 14), child: image),
                  if (isPlaying)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primary,
                        child: Icon(Icons.equalizer, size: 18, color: cs.onPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            container.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
          ),
          if (container.artist.isNotEmpty)
            Text(
              container.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium!.copyWith(color: cs.onSurfaceVariant),
            ),
          if (container.numTracks > 0)
            Text(i18n(context).card_tracks(container.numTracks), style: textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

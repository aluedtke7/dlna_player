import 'package:flutter/material.dart';

import 'package:dlna_player/component/card/topic_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/tile_style.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:dlna_player/model/raw_content.dart';

/// Row tile for artists, genres, folders and playlists.
class ContainerCard extends StatelessWidget {
  const ContainerCard({super.key, required this.container, required this.disabled});

  final RawContent container;
  final bool disabled;

  /// Folders are server categories (e.g. Jellyfin's "Alben", "Künstler"), whose
  /// cover is the same collection image for all of them, so they get an icon.
  bool get _isFolder => container.classType == ContentClass.folder || container.classType == ContentClass.none;

  IconData get _icon => switch (container.classType) {
    ContentClass.artist || ContentClass.artists => Icons.person_outline,
    ContentClass.genre => Icons.local_offer_outlined,
    ContentClass.playlist => Icons.queue_music,
    _ => categoryIcon(container.title),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Uri albumUri = Uri.parse(container.albumArt ?? '');
    final details = [
      container.artist,
      if (container.genre.isNotEmpty) i18n(context).card_genre(container.genre),
      if (container.numTracks > 0) i18n(context).card_tracks(container.numTracks),
    ].where((s) => s.isNotEmpty).join(' · ');

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: StyledTile(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (albumUri.hasScheme && !_isFolder)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  albumUri.toString(),
                  height: 48,
                  width: 48,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Image.asset('assets/images/error_album.png', height: 48, width: 48, fit: BoxFit.cover),
                ),
              )
            else
              IconBadge(icon: _icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    container.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (details.isNotEmpty)
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

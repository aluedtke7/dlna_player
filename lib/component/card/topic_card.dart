import 'package:flutter/material.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/tile_style.dart';
import 'package:dlna_player/model/content_container.dart';

/// Picks an icon for a top level server container by its (localized) name.
IconData categoryIcon(String title) {
  final t = title.toLowerCase();
  bool has(List<String> words) => words.any(t.contains);
  if (has(['playlist', 'wiedergabeliste'])) return Icons.queue_music;
  if (has(['recent', 'latest', 'newest', 'kürzlich', 'zuletzt', 'neueste'])) return Icons.schedule;
  if (has(['artist', 'interpret', 'künstler'])) return Icons.person_outline;
  if (has(['album', 'alben'])) return Icons.album_outlined;
  if (has(['genre'])) return Icons.local_offer_outlined;
  if (has(['titel', 'track', 'song', 'music', 'musik', 'audio'])) return Icons.music_note_outlined;
  if (t.contains('picture') || t.contains('photo') || t.contains('image') || t.contains('bild') || t.contains('foto')) {
    return Icons.image_outlined;
  }
  if (t.contains('video') || t.contains('movie') || t.contains('film')) return Icons.movie_outlined;
  return Icons.folder_outlined;
}

class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.topic, this.onTap});

  final ContentContainer topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return StyledTile(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconBadge(icon: categoryIcon(topic.title), size: 44),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topic.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                i18n(context).card_entries(topic.count),
                style: textTheme.bodySmall!.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

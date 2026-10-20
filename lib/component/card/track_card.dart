import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dlna_player/component/tile_style.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';

/// Formats a DLNA duration ("0:12:34.000" or Jellyfin's "00:12:34.000")
/// as "12:34", keeping the hours only when they are non-zero.
String formatTrackDuration(String raw) {
  if (raw.isEmpty) return '';
  final parts = raw.split('.').first.split(':');
  if (parts.length == 3 && int.tryParse(parts.first) == 0) {
    parts.removeAt(0);
  }
  return parts.join(':');
}

class TrackCard extends ConsumerWidget {
  const TrackCard({super.key, required this.track, required this.disabled, this.onTap});

  final RawContent track;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playingProvider);
    final isTrackActive = ref.watch(trackProvider).id == track.id;
    final isPlayingThis = isTrackActive && playing;
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Uri albumUri = Uri.parse(track.albumArt ?? '');
    final duration = formatTrackDuration(track.duration);

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: isTrackActive ? TileStyle.accentSoft(cs) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
            child: Row(
              children: [
                _TrackCover(albumUri: albumUri, showEqualizer: isPlayingThis, cs: cs),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700, color: isTrackActive ? cs.primary : null),
                      ),
                      if (track.artist.isNotEmpty)
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (duration.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    duration,
                    style: textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackCover extends StatelessWidget {
  const _TrackCover({
    required this.albumUri,
    required this.showEqualizer,
    required this.cs,
  });

  final Uri albumUri;
  final bool showEqualizer;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    const size = 48.0;
    Widget cover;
    if (albumUri.hasScheme) {
      cover = Image.network(
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
      );
    } else {
      cover = Container(
        width: size,
        height: size,
        color: cs.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.music_note, color: cs.onSurfaceVariant, size: 28),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cover,
            if (showEqualizer)
              Container(
                color: Colors.black.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: const _EqualizerBars(size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.size});

  final double size;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * 2 * math.pi;
          final h1 = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t));
          final h2 = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t + math.pi * 2 / 3));
          final h3 = 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t + math.pi * 4 / 3));
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(h1),
              const SizedBox(width: 2),
              _bar(h2),
              const SizedBox(width: 2),
              _bar(h3),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(double heightFactor) {
    return SizedBox(
      width: 3,
      child: FractionallySizedBox(
        heightFactor: heightFactor,
        alignment: Alignment.bottomCenter,
        child: const DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(1)),
          ),
        ),
      ),
    );
  }
}

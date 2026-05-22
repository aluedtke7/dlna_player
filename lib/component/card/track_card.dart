import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';

class TrackCard extends ConsumerWidget {
  const TrackCard({
    super.key,
    required this.track,
    required this.disabled,
    this.onTap,
  });

  final RawContent track;
  final bool disabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playingProvider);
    final isTrackActive = ref.watch(trackProvider).id == track.id;
    final isPlayingThis = isTrackActive && playing;
    final cs = Theme.of(context).colorScheme;

    final Uri albumUri = Uri.parse(track.albumArt ?? '');
    var duration = '';
    if (track.duration.isNotEmpty) {
      duration = track.duration.replaceFirst(RegExp('0:'), '');
      duration = duration.replaceFirst(RegExp(r'\.(\d+)'), '');
      // Jellyfin omits the first colon...
      final doubleZero = duration.contains(RegExp(r'00\d:'));
      if (doubleZero) {
        duration = duration.substring(1);
      }
    }
    final trDuration = duration.isNotEmpty ? i18n(context).card_duration(duration) : '';

    return Card(
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          width: double.maxFinite,
          decoration: isTrackActive
              ? BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  border: Border(left: BorderSide(color: cs.primary, width: 3)),
                )
              : null,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                textScaler: const TextScaler.linear(1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: disabled ? Theme.of(context).disabledColor : null,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (track.artist.isNotEmpty)
                          Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: disabled ? Theme.of(context).disabledColor : null,
                            ),
                          ),
                        if (track.duration.isNotEmpty)
                          Text(
                            trDuration,
                            style: TextStyle(
                              color: disabled ? Theme.of(context).disabledColor : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _TrackCover(
                    albumUri: albumUri,
                    showEqualizer: isPlayingThis,
                    cs: cs,
                  ),
                ],
              ),
            ],
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
    const size = 50.0;
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
      borderRadius: BorderRadius.circular(8),
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

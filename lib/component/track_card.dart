import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';

class TrackCard extends ConsumerStatefulWidget {
  const TrackCard({
    super.key,
    required this.track,
  });

  final RawContent track;

  @override
  ConsumerState<TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends ConsumerState<TrackCard> with SingleTickerProviderStateMixin {
  static const durationInS = 3;
  static const minOpacity = 0.2;
  static const maxOpacity = 0.9;
  bool playing = false;
  bool isTrackActive = false;
  late Animation<double> animation;
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: durationInS),
    );
    animation = Tween<double>(
      begin: maxOpacity,
      end: minOpacity,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        animationController.reverse();
      }
      if (status == AnimationStatus.dismissed && !playing && isTrackActive) {
        animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    playing = ref.watch(playingProvider);
    isTrackActive = ref.read(trackProvider).id == widget.track.id;

    final Uri albumUri = Uri.parse(widget.track.albumArt ?? '');
    var duration = '';
    if (widget.track.duration.isNotEmpty) {
      duration = widget.track.duration.replaceFirst(RegExp('0:'), '');
      duration = duration.replaceFirst(RegExp(r'\.(\d+)'), '');
      // Jellyfin omits the first colon...
      var doubleZero = duration.contains(RegExp(r'00\d:'));
      if (doubleZero) {
        duration = duration.substring(1);
      }
    }
    var trDuration = '';
    if (duration.isNotEmpty) trDuration = i18n(context).card_duration(duration);
    if (playing) {
      animationController.stop();
    } else if (isTrackActive) {
      animationController.forward();
    }
    return Card(
      elevation: 5,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (ctx, child) => Container(
          width: double.maxFinite,
          margin: const EdgeInsets.all(4),
          decoration: ref.read(trackProvider).id == widget.track.id
              ? BoxDecoration(
                  image: DecorationImage(
                    image: Image.asset('assets/images/play_bg.png').image,
                    opacity: playing ? maxOpacity : animation.value,
                  ),
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.track.title,
                textScaler: const TextScaler.linear(1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.track.artist.isNotEmpty)
                          Text(
                            widget.track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (widget.track.duration.isNotEmpty) Text(trDuration),
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
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/providers/audio_handler.dart';

class TrackNotifier extends Notifier<RawContent> {
  StreamSubscription? _subscription;

  @override
  RawContent build() {
    final handler = ref.watch(audioHandlerProvider);

    _subscription = handler.mediaItemStream.listen((item) {
      if (item != null) {
        final originalAlbumArt = item.extras?['originalAlbumArt'] as String?;
        state = RawContent(
          id: item.id,
          title: item.title,
          artist: item.artist ?? '',
          album: item.album ?? '',
          trackUrl: item.extras?['trackUrl'] as String?,
          albumArt: originalAlbumArt,
        );
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return RawContent();
  }

  void setTrack(RawContent newTrack) {
    state = newTrack;
  }
}

final trackProvider = NotifierProvider<TrackNotifier, RawContent>(() => TrackNotifier());

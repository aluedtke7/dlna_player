import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/providers/audio_handler.dart';

class PlaylistNotifier extends Notifier<List<RawContent>> {
  StreamSubscription? _subscription;

  @override
  List<RawContent> build() {
    final handler = ref.watch(audioHandlerProvider);

    // Convert MediaItem list to RawContent list
    List<RawContent> convert(List<MediaItem> items) {
      return items.map((item) {
        final originalAlbumArt = item.extras?['originalAlbumArt'] as String?;
        return RawContent(
          id: item.id,
          title: item.title,
          artist: item.artist ?? '',
          album: item.album ?? '',
          trackUrl: item.extras!['trackUrl'] as String? ?? '',
          albumArt: originalAlbumArt,
          duration: (item.duration?.inSeconds ?? 0).toString(),
        );
      }).toList();
    }

    // Set initial state
    state = convert(handler.queue.value);

    // Listen for queue changes
    _subscription = handler.queueStream.listen((queue) {
      state = convert(queue);
    });

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> setPlaylist(List<RawContent> newPlaylist) async {
    state = newPlaylist;
    final handler = ref.read(audioHandlerProvider);
    final currentQueue = handler.queue.value;

    // Compare current queue with new playlist by track IDs to avoid unnecessary reset
    if (currentQueue.length == newPlaylist.length) {
      bool identical = true;
      for (int i = 0; i < currentQueue.length; i++) {
        if (currentQueue[i].id != newPlaylist[i].id) {
          identical = false;
          break;
        }
      }
      if (identical) {
        // Playlist already matches, skip resetting the player
        return;
      }
    }
    await handler.setPlaylist(newPlaylist);
  }
}

final playlistProvider = NotifierProvider<PlaylistNotifier, List<RawContent>>(() => PlaylistNotifier());

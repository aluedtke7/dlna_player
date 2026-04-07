import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/providers/audio_handler.dart';

class PlaylistIndexNotifier extends Notifier<int> {
  StreamSubscription? _subscription;

  @override
  int build() {
    final handler = ref.watch(audioHandlerProvider);
    state = handler.currentIndex;

    _subscription = handler.currentIndexStream.listen((index) {
      state = index ?? 0;
    });

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  void setIndex(int newIndex) {
    state = newIndex;
    ref.read(audioHandlerProvider).skipToQueueItem(newIndex);
  }
}

final playlistIndexProvider = NotifierProvider<PlaylistIndexNotifier, int>(() => PlaylistIndexNotifier());

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/model/lyrics.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/providers/audio_handler.dart';
import 'package:dlna_player/providers/error_provider.dart';
import 'package:dlna_player/providers/lyrics_provider.dart';
import 'package:dlna_player/providers/track_provider.dart';
import 'package:dlna_player/service/genius_helper.dart';

final GeniusHelper geniusHelper = GeniusHelper();

class PlayingNotifier extends Notifier<bool> {
  StreamSubscription? _playingSubscription;

  @override
  bool build() {
    final handler = ref.watch(audioHandlerProvider);

    // Sync current modes to handler
    handler.setShuffle(ref.read(shuffleModeProvider));
    handler.setRepeat(ref.read(repeatModeProvider));

    // Listen for changes
    ref.listen<bool>(shuffleModeProvider, (prev, next) {
      handler.setShuffle(next);
    });
    ref.listen<bool>(repeatModeProvider, (prev, next) {
      handler.setRepeat(next);
    });

    _playingSubscription = handler.playerPlayingStream.listen((playing) {
      state = playing;
    });

    ref.onDispose(() {
      _playingSubscription?.cancel();
    });

    return false;
  }

  void playPauseTrack() {
    final handler = ref.read(audioHandlerProvider);
    if (state) {
      handler.pause();
    } else {
      handler.play();
    }
  }

  Future<void> handleError(String err) async {
    ref.read(errorProvider.notifier).setError(err.toString());
  }

  void playNextTrack() {
    ref.read(audioHandlerProvider).skipToNext();
  }

  void playPreviousTrack() {
    ref.read(audioHandlerProvider).skipToPrevious();
  }

  Future<void> getLyrics() async {
    ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.unknown));
    if (ref.read(showLyricsProvider)) {
      ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.loading));
      final track = ref.read(trackProvider);
      final lyrics = await geniusHelper.searchLyrics(track.artist, track.title);
      if (lyrics.text.isEmpty) {
        ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.empty));
      } else {
        ref.read(lyricsProvider.notifier).setLyrics(Lyrics(LyricsState.success, lyrics.text));
      }
    }
  }

  Future<void> updateGeniusToken(String geniusApiToken) async {
    geniusHelper.setToken(geniusApiToken);
  }

  void skipForward() {
    final handler = ref.read(audioHandlerProvider);
    final currentPos = handler.playbackState.value.updatePosition;
    handler.seek(currentPos + const Duration(seconds: 10));
  }

  void skipBackward() {
    final handler = ref.read(audioHandlerProvider);
    final currentPos = handler.playbackState.value.updatePosition;
    final newPos = currentPos > const Duration(seconds: 10) ? currentPos - const Duration(seconds: 10) : Duration.zero;
    handler.seek(newPos);
  }
}

final playingProvider = NotifierProvider<PlayingNotifier, bool>(() => PlayingNotifier());

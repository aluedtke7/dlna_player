import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/model/lyrics.dart';

class LyricsNotifier extends Notifier<Lyrics> {
  @override
  Lyrics build() => const Lyrics(LyricsState.unknown);

  void setLyrics(Lyrics newLyrics) {
    state = newLyrics;
  }
}

final lyricsProvider = NotifierProvider<LyricsNotifier, Lyrics>(() => LyricsNotifier());

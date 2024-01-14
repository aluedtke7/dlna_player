enum LyricsState {
  unknown,
  loading,
  notFound,
  empty,
  error,
  success;
}

class Lyrics {
  final LyricsState state;
  final String lyrics;

  const Lyrics(this.state, [this.lyrics = '']);
}

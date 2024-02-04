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
  final String text;

  const Lyrics(this.state, [this.text = '']);
}

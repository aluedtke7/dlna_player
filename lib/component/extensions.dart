String _twoDigits(int n) => n.toString().padLeft(2, "0");

extension DurationExt on Duration {
  String showHMS() {
    String twoDigitMinutes = _twoDigits(inMinutes.remainder(60));
    String twoDigitSeconds = _twoDigits(inSeconds.remainder(60));
    return "${_twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String showMS() {
    String twoDigitMinutes = _twoDigits(inMinutes.remainder(60) + inHours * 60);
    String twoDigitSeconds = _twoDigits(inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

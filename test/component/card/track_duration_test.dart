import 'package:dlna_player/component/card/track_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats MiniDLNA durations', () {
    expect(formatTrackDuration('0:03:45.000'), '03:45');
    expect(formatTrackDuration('0:12:34.000'), '12:34');
  });

  test('formats Jellyfin durations without leading zero', () {
    expect(formatTrackDuration('00:03:45.000'), '03:45');
    expect(formatTrackDuration('00:12:34.000'), '12:34');
  });

  test('keeps non-zero hours', () {
    expect(formatTrackDuration('1:10:00.000'), '1:10:00');
  });

  test('returns empty string for empty input', () {
    expect(formatTrackDuration(''), '');
  });
}

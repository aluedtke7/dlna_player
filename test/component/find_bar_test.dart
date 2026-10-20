import 'package:dlna_player/component/find_bar.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findMatches', () {
    final items = [
      RawContent(title: 'Clair de Lune', artist: 'Claude Debussy', album: 'Suite bergamasque'),
      RawContent(title: 'Aria', artist: 'Johann Sebastian Bach', album: 'Goldberg-Variationen'),
      RawContent(title: 'Prélude', artist: 'Claude Debussy', album: 'Suite bergamasque'),
    ];

    test('matches title, artist and album case insensitive', () {
      expect(findMatches(items, 'aria'), [1]);
      expect(findMatches(items, 'DEBUSSY'), [0, 2]);
      expect(findMatches(items, 'goldberg'), [1]);
    });

    test('returns nothing for an empty term or no match', () {
      expect(findMatches(items, '  '), isEmpty);
      expect(findMatches(items, 'Satie'), isEmpty);
    });
  });

  group('gridRowOffset', () {
    test('uses the fixed main axis extent of list tiles', () {
      const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 4,
      );
      // 1040 / 412 -> 3 columns, index 7 is in the third row.
      expect(gridRowOffset(delegate, 7, 1040), 2 * 76);
      expect(gridRowOffset(delegate, 2, 1040), 0);
    });

    test('derives the row height of cover tiles from the aspect ratio', () {
      const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 0.7,
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
      );
      // 1040 / 220 -> 5 columns of (1040 - 80) / 5 = 192 px.
      expect(gridRowOffset(delegate, 7, 1040), closeTo(192 / 0.7 + 24, 0.001));
    });
  });
}

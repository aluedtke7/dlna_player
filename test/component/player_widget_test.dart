import 'package:dlna_player/component/player_control/track_cover.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_widget_harness.dart';

void main() {
  const wide = Size(1000, 400);
  const phone = Size(390, 844);

  group('PlayerWidget', () {
    testWidgets('wide layout shows labelled mode buttons, title and artist', (tester) async {
      await pumpPlayerWidget(tester, size: wide);

      expect(find.text('Clair de Lune'), findsOneWidget);
      expect(find.text('Claude Debussy · Suite bergamasque'), findsOneWidget);
      expect(find.text('Zufall'), findsOneWidget);
      expect(find.text('Wiederholen'), findsOneWidget);
      expect(find.text('Songtext'), findsOneWidget);
      expect(find.text('02:14'), findsOneWidget);
      expect(find.text('05:03'), findsOneWidget);

      await disposePlayerWidget(tester);
    });

    testWidgets('compact layout uses icon toggles instead of labels', (tester) async {
      await pumpPlayerWidget(tester, size: phone);

      expect(find.text('Zufall'), findsNothing);
      expect(find.byTooltip('Setzt den Shuffle Modus'), findsOneWidget);
      expect(find.byTooltip('Zeigt / versteckt Liedtext (genius.com)'), findsOneWidget);

      await disposePlayerWidget(tester);
    });

    testWidgets('compact layout takes at most a quarter of the screen height', (tester) async {
      await pumpPlayerWidget(tester, size: phone);

      final height = tester.getSize(find.byType(AnimatedSize)).height;
      expect(height, lessThanOrEqualTo(phone.height / 4));

      await disposePlayerWidget(tester);
    });

    testWidgets('tapping the title collapses the widget', (tester) async {
      await pumpPlayerWidget(tester, size: wide);

      await tester.tap(find.text('Clair de Lune'));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Zufall'), findsNothing);
      expect(find.byTooltip('Setzt den Shuffle Modus'), findsNothing);
      expect(find.byTooltip('Play / Pause Lied'), findsOneWidget);

      await disposePlayerWidget(tester);
    });

    testWidgets('cover is only shown when the track has album art', (tester) async {
      await pumpPlayerWidget(tester, size: wide);
      expect(find.byType(TrackCover), findsNothing);
      await disposePlayerWidget(tester);

      await pumpPlayerWidget(tester, size: wide, track: RawContent(title: 'Clair de Lune', albumArt: 'http://localhost/cover.jpg'));
      expect(find.byType(TrackCover), findsOneWidget);
      await disposePlayerWidget(tester);
    });
  });
}

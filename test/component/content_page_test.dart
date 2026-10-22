import 'package:dlna_player/component/card/album_card.dart';
import 'package:dlna_player/component/card/container_card.dart';
import 'package:dlna_player/component/card/track_card.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/model/content_arguments.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/view/content_page.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'player_widget_harness.dart';

void main() {
  const wide = Size(1100, 760);

  testWidgets('albums are shown as cover tiles with breadcrumb title', (tester) async {
    final albums = [
      RawContent(id: 'a1', title: 'Suite bergamasque', artist: 'Claude Debussy', numTracks: 4, classType: ContentClass.album),
      RawContent(id: 'a2', title: 'Gymnopédies', artist: 'Erik Satie', numTracks: 3, classType: ContentClass.album),
    ];
    await pumpPage(tester, const ContentPage(), size: wide, arguments: ContentArguments('Music', albums));

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);
    expect(find.byType(AlbumCard), findsNWidgets(2));
    final playing = tester.widget<AlbumCard>(find.byType(AlbumCard).first);
    expect(playing.isPlaying, isTrue);

    await disposePlayerWidget(tester);
  });

  testWidgets('tracks are shown as rows', (tester) async {
    final tracks = [
      RawContent(id: 't1', title: 'Prélude', artist: 'Claude Debussy', duration: '0:04:52', classType: ContentClass.track),
      RawContent(id: 't2', title: 'Menuet', artist: 'Claude Debussy', duration: '0:04:59', classType: ContentClass.track),
    ];
    await pumpPage(tester, const ContentPage(), size: wide, arguments: ContentArguments('Music - Album', tracks));

    expect(find.text('Music / Album'), findsOneWidget);
    expect(find.byType(TrackCard), findsNWidgets(2));
    expect(find.text('04:52'), findsOneWidget);

    await disposePlayerWidget(tester);
  });

  testWidgets('container tiles all get the same size', (tester) async {
    final folders = [
      RawContent(id: 'f1', title: 'Album', classType: ContentClass.folder),
      RawContent(id: 'f2', title: 'Kürzlich hinzugefügt', genre: 'Klassik', numTracks: 12, classType: ContentClass.folder),
      RawContent(id: 'f3', title: 'Wiedergabelisten', classType: ContentClass.folder),
    ];
    await pumpPage(tester, const ContentPage(), size: const Size(390, 844), arguments: ContentArguments('Music', folders));

    final sizes = find.byType(ContainerCard).evaluate().map((e) => tester.getSize(find.byWidget(e.widget))).toSet();
    expect(sizes, hasLength(1));

    await disposePlayerWidget(tester);
  });

  testWidgets('search scrolls to the hit and jumps between hits', (tester) async {
    final tracks = [
      for (var i = 0; i < 80; i++) RawContent(id: 't$i', title: 'Track $i', artist: 'Artist', classType: ContentClass.track),
    ];
    tracks[60].title = 'Nocturne';
    tracks[70].title = 'Nocturne (live)';
    await pumpPage(tester, const ContentPage(), size: const Size(390, 844), arguments: ContentArguments('Music', tracks));
    expect(find.text('Nocturne'), findsNothing);

    await tester.tap(find.byTooltip('Strg + G\nSucht in der angezeigten Liste'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'noct');
    // Searching waits 750 ms after the last key stroke.
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('1 / 2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('Nocturne'), findsOneWidget);

    await tester.tap(find.byTooltip('Nächster Treffer (↓)'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Nocturne (live)'), findsOneWidget);

    await tester.tap(find.byTooltip('Vorheriger Treffer (↑)'));
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.text('1 / 2'), findsOneWidget);

    await disposePlayerWidget(tester);
  });

  testWidgets('Ctrl+G still opens the search after it was closed with Escape', (tester) async {
    final tracks = [RawContent(id: 't0', title: 'Track 0', artist: 'Artist', classType: ContentClass.track)];
    await pumpPage(tester, const ContentPage(), size: wide, arguments: ContentArguments('Music', tracks));

    Future<void> pressCtrlG() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
    }

    await pressCtrlG();
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    await pressCtrlG();
    expect(find.byType(TextField), findsOneWidget);

    await disposePlayerWidget(tester);
  });

  testWidgets('Ctrl+G still opens the search after Escape, when nothing had the focus before', (tester) async {
    final tracks = [RawContent(id: 't0', title: 'Track 0', artist: 'Artist', classType: ContentClass.track)];
    await pumpPage(tester, const ContentPage(), size: wide, arguments: ContentArguments('Music', tracks));
    // E.g. after a click, the focus rests on the route's scope above the page's shortcuts.
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();

    await tester.tap(find.byTooltip('Strg + G\nSucht in der angezeigten Liste'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);

    await disposePlayerWidget(tester);
  });

  testWidgets('the player gets the focus back after Escape, so the arrow keys reach it', (tester) async {
    final tracks = [RawContent(id: 't0', title: 'Track 0', artist: 'Artist', classType: ContentClass.track)];
    await pumpPage(tester, const ContentPage(), size: wide, arguments: ContentArguments('Music', tracks));
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();

    await tester.tap(find.byTooltip('Strg + G\nSucht in der angezeigten Liste'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(focused.findAncestorWidgetOfExactType<PlayerWidget>(), isNotNull);

    await disposePlayerWidget(tester);
  });

  testWidgets('Enter plays the current hit, also while the debounce is pending', (tester) async {
    final tracks = [
      for (var i = 0; i < 80; i++)
        RawContent(
          id: 't$i',
          title: i == 60 ? 'Nocturne' : 'Track $i',
          artist: 'Artist',
          trackUrl: 'http://localhost/t$i.mp3',
          classType: ContentClass.track,
        ),
    ];
    await pumpPage(tester, const ContentPage(), size: const Size(390, 844), arguments: ContentArguments('Music', tracks));

    await tester.tap(find.byTooltip('Strg + G\nSucht in der angezeigten Liste'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'noct');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pump();

    expect(find.text('1 / 1'), findsOneWidget);
    final container = ProviderScope.containerOf(tester.element(find.byType(ContentPage)));
    expect(container.read(trackProvider).id, 't60');
    expect(container.read(playlistIndexProvider), 60);
    // The player must start at the chosen track, not at the first one of the list.
    expect((container.read(playlistProvider.notifier) as FakePlaylist).initialIndex, 60);

    await disposePlayerWidget(tester);
  });

  for (final size in [const Size(390, 844), const Size(1100, 760)]) {
    testWidgets('scrolls the active track into view at $size', (tester) async {
      final tracks = [
        for (var i = 0; i < 600; i++) RawContent(id: 't$i', title: 'Track $i', artist: 'Artist', classType: ContentClass.track),
      ];
      await pumpPage(tester, const ContentPage(), size: size, arguments: ContentArguments('Music', tracks));
      final container = ProviderScope.containerOf(tester.element(find.byType(ContentPage)));
      await container.read(playlistProvider.notifier).setPlaylist(tracks);

      for (final index in [70, 400, 401, 550, 3]) {
        container.read(playlistIndexProvider.notifier).setIndex(index);
        await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));

        final grid = tester.getRect(find.byType(GridView));
        final tile = tester.getRect(find.ancestor(of: find.text('Track $index'), matching: find.byType(TrackCard)));
        expect(grid.top <= tile.top && tile.bottom <= grid.bottom, isTrue, reason: 'Track $index at $tile outside $grid');
      }

      await disposePlayerWidget(tester);
    });
  }
}

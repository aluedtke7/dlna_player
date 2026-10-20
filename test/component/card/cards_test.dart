import 'package:dlna_player/component/card/album_card.dart';
import 'package:dlna_player/component/card/container_card.dart';
import 'package:dlna_player/component/card/device_card.dart';
import 'package:dlna_player/component/card/topic_card.dart';
import 'package:dlna_player/component/tile_style.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:dlna_player/model/content_container.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upnp2/upnp.dart' show Device;

Widget _app(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: brightness)),
  locale: const Locale('de'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: SizedBox(width: 300, child: child))),
);

void main() {
  group('categoryIcon', () {
    test('maps known MiniDLNA and Jellyfin containers', () {
      expect(categoryIcon('Music'), Icons.music_note_outlined);
      expect(categoryIcon('Musik'), Icons.music_note_outlined);
      expect(categoryIcon('Pictures'), Icons.image_outlined);
      expect(categoryIcon('Video'), Icons.movie_outlined);
      expect(categoryIcon('Playlists'), Icons.queue_music);
    });

    test('maps the German MiniDLNA music containers', () {
      expect(categoryIcon('Album'), Icons.album_outlined);
      expect(categoryIcon('Alle Titel'), Icons.music_note_outlined);
      expect(categoryIcon('Genre'), Icons.local_offer_outlined);
      expect(categoryIcon('Interpret'), Icons.person_outline);
      expect(categoryIcon('Kürzlich hinzugefügt'), Icons.schedule);
      expect(categoryIcon('Ordner'), Icons.folder_outlined);
      expect(categoryIcon('Wiedergabelisten'), Icons.queue_music);
    });

    test('maps the German Jellyfin music folders', () {
      expect(categoryIcon('Neueste'), Icons.schedule);
      expect(categoryIcon('Wiedergabelisten'), Icons.queue_music);
      expect(categoryIcon('Alben'), Icons.album_outlined);
      expect(categoryIcon('Album-Künstler'), Icons.person_outline);
      expect(categoryIcon('Künstler'), Icons.person_outline);
      expect(categoryIcon('Titel'), Icons.music_note_outlined);
      expect(categoryIcon('Genres'), Icons.local_offer_outlined);
      expect(categoryIcon('Lieblingskünstler'), Icons.person_outline);
      expect(categoryIcon('Lieblingsalben'), Icons.album_outlined);
      expect(categoryIcon('Lieblingstitel'), Icons.music_note_outlined);
    });

    test('artist wins over album for album artists', () {
      expect(categoryIcon('Album Artist'), Icons.person_outline);
    });

    test('falls back to a folder', () {
      expect(categoryIcon('Browse Folders'), Icons.folder_outlined);
      expect(categoryIcon(''), Icons.folder_outlined);
    });
  });

  group('TileStyle', () {
    test('accent tint is stronger in dark themes', () {
      final light = ColorScheme.fromSeed(seedColor: Colors.green);
      final dark = ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark);
      expect(TileStyle.accentSoft(light).a, closeTo(0.10, 0.01));
      expect(TileStyle.accentSoft(dark).a, closeTo(0.16, 0.01));
    });
  });

  testWidgets('DeviceCard shows name and origin and reacts to taps', (tester) async {
    var tapped = false;
    final device =
        Device()
          ..friendlyName = 'MiniDLNA'
          ..urlBase = 'http://192.168.1.20:8200/rootDesc.xml';
    await tester.pumpWidget(_app(DeviceCard(device: device, onTap: () => tapped = true)));

    expect(find.text('MiniDLNA'), findsOneWidget);
    expect(find.text('http://192.168.1.20:8200'), findsOneWidget);
    await tester.tap(find.byType(DeviceCard));
    expect(tapped, isTrue);
  });

  testWidgets('TopicCard shows title and entry count', (tester) async {
    await tester.pumpWidget(_app(SizedBox(height: 148, child: TopicCard(topic: ContentContainer(title: 'Music', count: 7)))));

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('7 Einträge'), findsOneWidget);
    expect(find.byIcon(Icons.music_note_outlined), findsOneWidget);
  });

  testWidgets('AlbumCard marks the playing album', (tester) async {
    final album = RawContent(title: 'Suite bergamasque', artist: 'Claude Debussy', numTracks: 4);
    await tester.pumpWidget(_app(AlbumCard(container: album, disabled: false)));
    expect(find.text('4 Titel'), findsOneWidget);
    expect(find.byIcon(Icons.equalizer), findsNothing);

    await tester.pumpWidget(_app(AlbumCard(container: album, disabled: false, isPlaying: true)));
    expect(find.byIcon(Icons.equalizer), findsOneWidget);
  });

  testWidgets('folder tiles show a category icon instead of the shared collection image', (tester) async {
    final folder = RawContent(title: 'Alben', albumArt: 'http://localhost/musik.jpg', classType: ContentClass.folder);
    await tester.pumpWidget(_app(ContainerCard(container: folder, disabled: false)));

    expect(find.byIcon(Icons.album_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}

import 'package:dlna_player/component/custom_themes.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/src/generated/i18n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

final testTrack = RawContent(title: 'Clair de Lune', artist: 'Claude Debussy', album: 'Suite bergamasque');

class _FakeTrack extends TrackNotifier {
  final RawContent track;

  _FakeTrack(this.track);

  @override
  RawContent build() => track;
}

class _FakePlaying extends PlayingNotifier {
  @override
  bool build() => true;

  @override
  Future<void> getLyrics() async {}
}

class _FakePlayTime extends PlayTimeNotifier {
  @override
  Duration build() => const Duration(minutes: 2, seconds: 14);
}

class _FakeEndTime extends EndTimeNotifier {
  @override
  Duration build() => const Duration(minutes: 5, seconds: 3);
}

class FakePlaylist extends PlaylistNotifier {
  /// Start index passed by the last [setPlaylist] call.
  int? initialIndex;

  @override
  List<RawContent> build() => [testTrack, RawContent(title: 'Rêverie')];

  @override
  Future<void> setPlaylist(List<RawContent> newPlaylist, {int initialIndex = 0}) async {
    this.initialIndex = initialIndex;
    state = newPlaylist;
  }
}

class _FakePlaylistIndex extends PlaylistIndexNotifier {
  @override
  int build() => 0;

  @override
  void setIndex(int newIndex) => state = newIndex;
}

class _FakeVolume extends VolumeNotifier {
  @override
  double build() => 0.6;
}

/// Pumps a PlayerWidget at the bottom of a [size] sized screen with faked
/// player state, so no audio handler or DLNA server is needed.
Future<void> pumpPlayerWidget(
  WidgetTester tester, {
  required Size size,
  String themeId = 'light-green',
  bool expanded = true,
  RawContent? track,
}) => pumpPage(
  tester,
  const Scaffold(body: Column(mainAxisAlignment: MainAxisAlignment.end, children: [PlayerWidget('')])),
  size: size,
  themeId: themeId,
  expanded: expanded,
  track: track,
);

/// Pumps [page] as the only route, with [arguments] as its route arguments
/// and the same faked player state as [pumpPlayerWidget].
Future<void> pumpPage(
  WidgetTester tester,
  Widget page, {
  required Size size,
  Object? arguments,
  String themeId = 'light-green',
  bool expanded = true,
  RawContent? track,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({PrefKeys.playerWidgetExpandStatePrefsKey: expanded});

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        trackProvider.overrideWith(() => _FakeTrack(track ?? testTrack)),
        playingProvider.overrideWith(_FakePlaying.new),
        playTimeProvider.overrideWith(_FakePlayTime.new),
        endTimeProvider.overrideWith(_FakeEndTime.new),
        playlistProvider.overrideWith(FakePlaylist.new),
        volumeProvider.overrideWith(_FakeVolume.new),
        playlistIndexProvider.overrideWith(_FakePlaylistIndex.new),
      ],
      child: ThemeProvider(
        themes: customThemes,
        defaultThemeId: themeId,
        child: ThemeConsumer(
          child: Builder(
            builder:
                (context) => MaterialApp(
                  theme: ThemeProvider.themeOf(context).data,
                  locale: const Locale('de'),
                  localizationsDelegates: AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => page, settings: RouteSettings(arguments: arguments)),
                ),
          ),
        ),
      ),
    ),
  );
  // Let the prefs load and the expansion animation finish.
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

/// Unmounts the widget so its timers are cancelled before the test ends.
Future<void> disposePlayerWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 5));
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/player_control/animated_volume.dart';
import 'package:dlna_player/component/player_control/artist_title_fader.dart';
import 'package:dlna_player/component/player_control/track_cover.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/service/events.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

const double iconSize = 32;

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget(String trackTitle, {super.key});

  @override
  ConsumerState<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends ConsumerState<PlayerWidget> {
  var sliderPos = 0.0;
  var sliderIsMoving = false;
  var showArtist = false;
  var isExpanded = false;
  var isShuffle = false;
  var isRepeat = false;
  var isLyrics = false;
  var showVolume = true;
  late Timer toggleTimer;
  late RestartableTimer volumeHideTimer;

  @override
  void initState() {
    super.initState();
    toggleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() => showArtist = !showArtist);
    });
    volumeHideTimer = RestartableTimer(Duration(seconds: 4), () {
      if (mounted) {
        setState(() => showVolume = false);
      }
    });
    _loadPrefs();
    eventBus.on<VolumeChangedEvent>().listen((volume) {
      if (mounted) {
        setState(() => showVolume = true);
        volumeHideTimer.reset();
      }
    });
  }

  @override
  void dispose() {
    toggleTimer.cancel();
    volumeHideTimer.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final expand = prefs.getBool(PrefKeys.playerWidgetExpandStatePrefsKey) ?? true;
    ref.read(playerWidgetExpansionProvider.notifier).state = expand;
    final shuffle = prefs.getBool(PrefKeys.playerWidgetShuffleStatePrefsKey) ?? false;
    ref.read(shuffleModeProvider.notifier).state = shuffle;
    final repeat = prefs.getBool(PrefKeys.playerWidgetRepeatStatePrefsKey) ?? false;
    ref.read(repeatModeProvider.notifier).state = repeat;
    ref.read(showLyricsProvider.notifier).state = false;
    final geniusApiToken = prefs.getString(PrefKeys.geniusApiTokenPrefsKey) ?? '';
    ref.read(playingProvider.notifier).updateGeniusToken(geniusApiToken);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(PrefKeys.playerWidgetExpandStatePrefsKey, isExpanded);
    prefs.setBool(PrefKeys.playerWidgetShuffleStatePrefsKey, isShuffle);
    prefs.setBool(PrefKeys.playerWidgetRepeatStatePrefsKey, isRepeat);
  }

  @override
  Widget build(BuildContext context) {
    final trackRef = ref.watch(trackProvider);
    final playingRef = ref.watch(playingProvider);
    final playTimeRef = ref.watch(playTimeProvider);
    final endTimeRef = ref.watch(endTimeProvider);
    final playlistRef = ref.watch(playlistProvider);
    final volumeRef = ref.watch(volumeProvider);
    isExpanded = ref.watch(playerWidgetExpansionProvider);
    isShuffle = ref.watch(shuffleModeProvider);
    isRepeat = ref.watch(repeatModeProvider);
    isLyrics = ref.read(showLyricsProvider);

    if (!sliderIsMoving) {
      if (endTimeRef.inSeconds == 0) {
        sliderPos = 0;
      } else {
        sliderPos = min(1.0, playTimeRef.inMilliseconds.toDouble() / endTimeRef.inMilliseconds.toDouble());
      }
    }

    return Stack(
      children: [
        AnimatedSize(
          curve: Curves.decelerate,
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: Platform.isIOS ? const EdgeInsets.only(bottom: 8) : null,
            decoration: BoxDecoration(
              color: ThemeProvider.optionsOf<ThemeOptions>(context).playerWidgetBackgroundColor,
            ),
            child: Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  flex: 10,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 4,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 8,
                          right: 8,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            isExpanded = !isExpanded;
                            ref.read(playerWidgetExpansionProvider.notifier).state = isExpanded;
                            _savePrefs();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 45, child: Text(playTimeRef.showMS())),
                              Expanded(
                                child: ArtistTitleFader(
                                  artist: trackRef.artist,
                                  title: trackRef.title,
                                  showArtist: showArtist,
                                ),
                              ),
                              SizedBox(
                                  width: 45,
                                  child: Text(
                                    endTimeRef.showMS(),
                                    textAlign: TextAlign.end,
                                  )),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: trackRef.title.isNotEmpty
                                ? () => ref.read(playingProvider.notifier).playPauseTrack()
                                : null,
                            icon: Icon(playingRef ? Icons.pause : Icons.play_arrow, size: iconSize),
                            tooltip: i18n(context).pw_hint_play_pause,
                          ),
                          Expanded(
                            child: Slider(
                              value: sliderPos,
                              onChanged: (value) {
                                setState(() {
                                  sliderPos = min(1.0, value);
                                });
                              },
                              onChangeStart: (value) {
                                setState(() {
                                  sliderIsMoving = true;
                                });
                              },
                              onChangeEnd: (value) {
                                final newCurrent = Duration(seconds: (value * endTimeRef.inSeconds).toInt());
                                ref.read(playerProvider).seek(newCurrent).then((_) {
                                  setState(() {
                                    sliderIsMoving = false;
                                  });
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        Text(
                          trackRef.album,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {
                                isShuffle = !isShuffle;
                                ref.read(shuffleModeProvider.notifier).state = isShuffle;
                                _savePrefs();
                                Statics.showInfoSnackbar(
                                    context, i18n(context).player_shuffle_mode(isShuffle.toString()));
                              },
                              icon: Icon(Icons.shuffle, size: iconSize, color: !isShuffle ? Colors.grey : null),
                              tooltip: i18n(context).pw_hint_shuffle,
                            ),
                            IconButton(
                              onPressed: playlistRef.length > 1
                                  ? () => ref.read(playingProvider.notifier).playPreviousTrack()
                                  : null,
                              icon: const Icon(Icons.skip_previous, size: iconSize),
                              tooltip: i18n(context).pw_hint_previous,
                            ),
                            IconButton(
                              onPressed: playlistRef.length > 1
                                  ? () {
                                      ref.read(playingProvider.notifier).playNextTrack();
                                    }
                                  : null,
                              icon: const Icon(Icons.skip_next, size: iconSize),
                              tooltip: i18n(context).pw_hint_next,
                            ),
                            IconButton(
                              onPressed: () {
                                isRepeat = !isRepeat;
                                ref.read(repeatModeProvider.notifier).state = isRepeat;
                                _savePrefs();
                                Statics.showInfoSnackbar(
                                    context, i18n(context).player_repeat_mode(isRepeat.toString()));
                              },
                              icon: Icon(Icons.repeat, size: iconSize, color: !isRepeat ? Colors.grey : null),
                              tooltip: i18n(context).pw_hint_repeat,
                            ),
                            IconButton(
                              onPressed: () {
                                isLyrics = !isLyrics;
                                ref.read(showLyricsProvider.notifier).state = isLyrics;
                                if (isLyrics && ref.read(lyricsProvider).text.isEmpty) {
                                  ref.read(playingProvider.notifier).getLyrics();
                                }
                                _savePrefs();
                              },
                              icon: Icon(
                                Icons.text_snippet_outlined,
                                size: iconSize,
                                color: !isLyrics ? Colors.grey : null,
                              ),
                              tooltip: i18n(context).pw_hint_lyrics,
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                if (isExpanded && (trackRef.albumArt?.isNotEmpty ?? false))
                  TrackCover(coverUrl: trackRef.albumArt.toString()),
              ],
            ),
          ),
        ),
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
          Positioned(left: 120, top: 8, child: AnimatedVolume(show: showVolume, volume: volumeRef)),
      ],
    );
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/player_control/animated_volume.dart';
import 'package:dlna_player/component/player_control/artist_title_fader.dart';
import 'package:dlna_player/component/player_control/track_cover.dart';
import 'package:dlna_player/component/snackbar.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/service/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

const double iconSize = 32;

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget(String trackTitle, {super.key});

  @override
  ConsumerState<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends ConsumerState<PlayerWidget> with SingleTickerProviderStateMixin {
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
  late AnimationController playPauseController;

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
    playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
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
    playPauseController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final expand = prefs.getBool(PrefKeys.playerWidgetExpandStatePrefsKey) ?? true;
    ref.read(playerWidgetExpansionProvider.notifier).setExpansion(expand);
    final shuffle = prefs.getBool(PrefKeys.playerWidgetShuffleStatePrefsKey) ?? false;
    ref.read(shuffleModeProvider.notifier).setShuffle(shuffle);
    final repeat = prefs.getBool(PrefKeys.playerWidgetRepeatStatePrefsKey) ?? false;
    ref.read(repeatModeProvider.notifier).setRepeat(repeat);
    ref.read(showLyricsProvider.notifier).setShowLyrics(false);
    final geniusApiToken = prefs.getString(PrefKeys.geniusApiTokenPrefsKey) ?? '';
    ref.read(playingProvider.notifier).updateGeniusToken(geniusApiToken);
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(PrefKeys.playerWidgetExpandStatePrefsKey, isExpanded);
    prefs.setBool(PrefKeys.playerWidgetShuffleStatePrefsKey, isShuffle);
    prefs.setBool(PrefKeys.playerWidgetRepeatStatePrefsKey, isRepeat);
  }

  void showError(BuildContext context, String err) async {
    if (err != '') {
      Future(() {
        ref.read(errorProvider.notifier).setError('');
      });
      SnackbarHelper.showErrorSnackbar(context, err);
    }
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
    // Drive the play/pause AnimatedIcon from the playing state.
    if (playingRef && playPauseController.status != AnimationStatus.completed) {
      playPauseController.forward();
    } else if (!playingRef && playPauseController.status != AnimationStatus.dismissed) {
      playPauseController.reverse();
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      showError(context, ref.watch(errorProvider));
    });

    final cs = Theme.of(context).colorScheme;
    final widgetBg = ThemeProvider.optionsOf<ThemeOptions>(context).playerWidgetBackgroundColor;
    final gradientEnd = Color.lerp(widgetBg, cs.surface, 0.45) ?? widgetBg;
    return Stack(
      children: [
        AnimatedSize(
          curve: Curves.decelerate,
          duration: const Duration(milliseconds: 500),
          child: Container(
            padding: Platform.isIOS ? const EdgeInsets.only(bottom: 8) : null,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [widgetBg, gradientEnd],
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  flex: 10,
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: GestureDetector(
                          onTap: () {
                            isExpanded = !isExpanded;
                            ref.read(playerWidgetExpansionProvider.notifier).setExpansion(isExpanded);
                            _savePrefs();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              SizedBox(width: 45, child: Text(playTimeRef.showMS())),
                              Expanded(child: ArtistTitleFader(artist: trackRef.artist, title: trackRef.title, showArtist: showArtist)),
                              SizedBox(width: 45, child: Text(endTimeRef.showMS(), textAlign: TextAlign.end)),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: IconButton.filled(
                              onPressed: trackRef.title.isNotEmpty ? () => ref.read(playingProvider.notifier).playPauseTrack() : null,
                              icon: AnimatedIcon(
                                icon: AnimatedIcons.play_pause,
                                progress: playPauseController,
                                size: iconSize,
                                color: cs.onPrimary,
                              ),
                              tooltip: i18n(context).pw_hint_play_pause,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: cs.primary,
                                inactiveTrackColor: cs.primary.withValues(alpha: 0.18),
                                thumbColor: cs.primary,
                                overlayColor: cs.primary.withValues(alpha: 0.16),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8,
                                  elevation: 2,
                                  pressedElevation: 8,
                                ),
                              ),
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
                                  ref.read(audioHandlerProvider).seek(newCurrent).then((_) {
                                    setState(() {
                                      sliderIsMoving = false;
                                    });
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        Text(trackRef.album, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            IconButton(
                              onPressed: () {
                                isShuffle = !isShuffle;
                                ref.read(shuffleModeProvider.notifier).setShuffle(isShuffle);
                                _savePrefs();
                                SnackbarHelper.showInfoSnackbar(context, i18n(context).player_shuffle_mode(isShuffle.toString()));
                              },
                              icon: Icon(Icons.shuffle, size: iconSize, color: !isShuffle ? Colors.grey : null),
                              tooltip: i18n(context).pw_hint_shuffle,
                            ),
                            IconButton(
                              onPressed: playlistRef.length > 1 ? () => ref.read(playingProvider.notifier).playPreviousTrack() : null,
                              icon: const Icon(Icons.skip_previous, size: iconSize),
                              tooltip: i18n(context).pw_hint_previous,
                            ),
                            IconButton(
                              onPressed: playlistRef.length > 1 ? () => ref.read(playingProvider.notifier).playNextTrack() : null,
                              icon: const Icon(Icons.skip_next, size: iconSize),
                              tooltip: i18n(context).pw_hint_next,
                            ),
                            IconButton(
                              onPressed: () {
                                isRepeat = !isRepeat;
                                ref.read(repeatModeProvider.notifier).setRepeat(isRepeat);
                                _savePrefs();
                                SnackbarHelper.showInfoSnackbar(context, i18n(context).player_repeat_mode(isRepeat.toString()));
                              },
                              icon: Icon(Icons.repeat, size: iconSize, color: !isRepeat ? Colors.grey : null),
                              tooltip: i18n(context).pw_hint_repeat,
                            ),
                            IconButton(
                              onPressed: () {
                                isLyrics = !isLyrics;
                                ref.read(showLyricsProvider.notifier).setShowLyrics(isLyrics);
                                if (isLyrics && ref.read(lyricsProvider).text.isEmpty) {
                                  ref.read(playingProvider.notifier).getLyrics();
                                }
                                _savePrefs();
                              },
                              icon: Icon(Icons.text_snippet_outlined, size: iconSize, color: !isLyrics ? Colors.grey : null),
                              tooltip: i18n(context).pw_hint_lyrics,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (isExpanded && (trackRef.albumArt?.isNotEmpty ?? false)) TrackCover(coverUrl: trackRef.albumArt.toString()),
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

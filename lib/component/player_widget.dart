import 'dart:io';
import 'dart:math';

import 'package:dlna_player/component/theme_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';

import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

const double iconSize = 32;

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget(String trackTitle, {Key? key}) : super(key: key);

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
  late Timer toggleTimer;

  @override
  void initState() {
    super.initState();
    toggleTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        showArtist = !showArtist;
      });
    });
    _loadPrefs();
  }

  @override
  void dispose() {
    toggleTimer.cancel();
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
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(PrefKeys.playerWidgetExpandStatePrefsKey, isExpanded);
    prefs.setBool(PrefKeys.playerWidgetShuffleStatePrefsKey, isShuffle);
    prefs.setBool(PrefKeys.playerWidgetRepeatStatePrefsKey, isRepeat);
  }

  @override
  Widget build(BuildContext context) {
    final double imageSize;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      imageSize = 150.0;
    } else {
      imageSize = 90.0;
    }
    final mq = MediaQuery.of(context);
    final trackRef = ref.watch(trackProvider);
    final playingRef = ref.watch(playingProvider);
    final playTimeRef = ref.watch(playTimeProvider);
    final endTimeRef = ref.watch(endTimeProvider);
    final playlistRef = ref.watch(playlistProvider);
    isExpanded = ref.watch(playerWidgetExpansionProvider);
    isShuffle = ref.watch(shuffleModeProvider);
    isRepeat = ref.watch(repeatModeProvider);

    if (!sliderIsMoving) {
      if (endTimeRef.inSeconds == 0) {
        sliderPos = 0;
      } else {
        sliderPos = playTimeRef.inSeconds / endTimeRef.inSeconds;
      }
    }

    return AnimatedSize(
      curve: Curves.decelerate,
      duration: const Duration(milliseconds: 500),
      child: Container(
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
                            child: AnimatedCrossFade(
                              firstChild: SizedBox(
                                width: mq.size.width - 110,
                                child: Text(
                                  trackRef.title,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              secondChild: SizedBox(
                                width: mq.size.width - 110,
                                child: Text(
                                  trackRef.artist,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              crossFadeState: showArtist ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 500),
                              sizeCurve: Curves.bounceInOut,
                            ),
                          ),
                          SizedBox(
                              width: 40,
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
                    if (trackRef.album.isNotEmpty)
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
                                context, AppLocalizations.of(context)?.player_shuffle_mode(isShuffle.toString()) ?? '');
                          },
                          icon: Icon(Icons.shuffle, size: iconSize, color: !isShuffle ? Colors.grey : null),
                        ),
                        IconButton(
                          onPressed: playlistRef.length > 1
                              ? () => ref.read(playingProvider.notifier).playPreviousTrack()
                              : null,
                          icon: const Icon(Icons.skip_previous, size: iconSize),
                        ),
                        IconButton(
                          onPressed: playlistRef.length > 1
                              ? () {
                                  ref.read(playingProvider.notifier).playNextTrack();
                                }
                              : null,
                          icon: const Icon(Icons.skip_next, size: iconSize),
                        ),
                        IconButton(
                          onPressed: () {
                            isRepeat = !isRepeat;
                            ref.read(repeatModeProvider.notifier).state = isRepeat;
                            _savePrefs();
                            Statics.showInfoSnackbar(
                                context, AppLocalizations.of(context)?.player_repeat_mode(isRepeat.toString()) ?? '');
                          },
                          icon: Icon(Icons.repeat, size: iconSize, color: !isRepeat ? Colors.grey : null),
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
            if (isExpanded && (trackRef.albumArt?.isNotEmpty ?? false))
              Flexible(
                fit: FlexFit.loose,
                flex: 0,
                child: SizedBox(
                  width: imageSize,
                  child: Image.network(
                    trackRef.albumArt.toString(),
                    height: imageSize,
                    width: imageSize,
                    alignment: Alignment.centerRight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/error_album.png',
                      height: imageSize,
                      width: imageSize,
                      alignment: Alignment.centerRight,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            const SizedBox(
              width: 4,
            )
          ],
        ),
      ),
    );
  }
}

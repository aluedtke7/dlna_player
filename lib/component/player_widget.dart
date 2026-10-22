import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:async/async.dart';
import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/player_control/animated_volume.dart';
import 'package:dlna_player/component/player_control/player_colors.dart';
import 'package:dlna_player/component/player_control/track_cover.dart';
import 'package:dlna_player/component/snackbar.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/service/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

/// Below this width the compact (smartphone) layout is used.
const double compactBreakpoint = 700;

class PlayerWidget extends ConsumerStatefulWidget {
  const PlayerWidget(String trackTitle, {super.key});

  @override
  ConsumerState<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends ConsumerState<PlayerWidget> with SingleTickerProviderStateMixin {
  var sliderPos = 0.0;
  var sliderIsMoving = false;
  var isExpanded = false;
  var isShuffle = false;
  var isRepeat = false;
  var isLyrics = false;
  var showVolume = true;
  late RestartableTimer volumeHideTimer;
  late AnimationController playPauseController;
  final focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    volumeHideTimer = RestartableTimer(Duration(seconds: 4), () {
      if (mounted) {
        setState(() => showVolume = false);
      }
    });
    playPauseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    FocusManager.instance.addListener(reclaimFocus);
    _loadPrefs();
    eventBus.on<VolumeChangedEvent>().listen((volume) {
      if (mounted) {
        setState(() => showVolume = true);
        volumeHideTimer.reset();
      }
    });
  }

  /// Takes the focus back when it rests on an ancestor like the route's scope,
  /// otherwise the arrow keys move the focus between the tiles.
  void reclaimFocus() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary != focusNode && focusNode.ancestors.contains(primary)) {
      focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(reclaimFocus);
    volumeHideTimer.cancel();
    playPauseController.dispose();
    focusNode.dispose();
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

  void _toggleExpanded() {
    isExpanded = !isExpanded;
    ref.read(playerWidgetExpansionProvider.notifier).setExpansion(isExpanded);
    _savePrefs();
  }

  void _toggleShuffle() {
    isShuffle = !isShuffle;
    ref.read(shuffleModeProvider.notifier).setShuffle(isShuffle);
    _savePrefs();
    SnackbarHelper.showInfoSnackbar(context, i18n(context).player_shuffle_mode(isShuffle.toString()));
  }

  void _toggleRepeat() {
    isRepeat = !isRepeat;
    ref.read(repeatModeProvider.notifier).setRepeat(isRepeat);
    _savePrefs();
    SnackbarHelper.showInfoSnackbar(context, i18n(context).player_repeat_mode(isRepeat.toString()));
  }

  void _toggleLyrics() {
    isLyrics = !isLyrics;
    ref.read(showLyricsProvider.notifier).setShowLyrics(isLyrics);
    if (isLyrics && ref.read(lyricsProvider).text.isEmpty) {
      ref.read(playingProvider.notifier).getLyrics();
    }
    _savePrefs();
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

    final colors = PlayerColors.of(
      Theme.of(context).colorScheme,
      ThemeProvider.optionsOf<ThemeOptions>(context).playerWidgetBackgroundColor,
    );
    final hasTrack = trackRef.title.isNotEmpty;
    final canSkip = playlistRef.length > 1;
    final hasCover = trackRef.albumArt?.isNotEmpty ?? false;

    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.space) {
            if (trackRef.title.isNotEmpty) {
              ref.read(playingProvider.notifier).playPauseTrack();
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            ref.read(volumeProvider.notifier).increaseVolume();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            ref.read(volumeProvider.notifier).decreaseVolume();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            ref.read(playingProvider.notifier).skipForward();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            ref.read(playingProvider.notifier).skipBackward();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        children: [
          AnimatedSize(
            curve: Curves.decelerate,
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: double.infinity,
              color: colors.background,
              padding: Platform.isIOS ? const EdgeInsets.only(bottom: 8) : null,
              child: DefaultTextStyle.merge(
                style: TextStyle(color: colors.foreground),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < compactBreakpoint;
                    if (!isExpanded) {
                      return _buildCollapsed(colors, trackRef, hasTrack, playTimeRef, endTimeRef);
                    }
                    if (compact) {
                      return _buildCompact(colors, trackRef, hasTrack, hasCover, canSkip, playTimeRef, endTimeRef);
                    }
                    return _buildWide(colors, trackRef, hasTrack, hasCover, canSkip, playTimeRef, endTimeRef);
                  },
                ),
              ),
            ),
          ),
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
            Positioned(right: 16, top: 8, child: AnimatedVolume(show: showVolume, volume: volumeRef)),
        ],
      ),
    );
  }

  /// Collapsed: play button next to title and seek bar.
  Widget _buildCollapsed(PlayerColors colors, RawContent track, bool hasTrack, Duration playTime, Duration endTime) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 6),
      child: Row(
        children: [
          _playButton(colors, 48, hasTrack),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleBlock(colors, track, Theme.of(context).textTheme.titleMedium!, singleLine: true),
                _seekBar(colors, playTime, endTime, 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Smartphone: cover and title, seek bar, one row with all controls.
  Widget _buildCompact(
    PlayerColors colors,
    RawContent track,
    bool hasTrack,
    bool hasCover,
    bool canSkip,
    Duration playTime,
    Duration endTime,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (hasCover) ...[TrackCover(coverUrl: track.albumArt.toString(), size: 56), const SizedBox(width: 12)],
              Expanded(child: _titleBlock(colors, track, Theme.of(context).textTheme.titleLarge!)),
            ],
          ),
          const SizedBox(height: 4),
          _seekBar(colors, playTime, endTime, 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _toggleIcon(colors, isShuffle, Icons.shuffle, i18n(context).pw_hint_shuffle, _toggleShuffle),
              _skipButton(colors, Icons.skip_previous, i18n(context).pw_hint_previous, canSkip, previous: true),
              _playButton(colors, 56, hasTrack),
              _skipButton(colors, Icons.skip_next, i18n(context).pw_hint_next, canSkip, previous: false),
              _toggleIcon(colors, isRepeat, Icons.repeat, i18n(context).pw_hint_repeat, _toggleRepeat),
              _toggleIcon(colors, isLyrics, Icons.text_snippet_outlined, i18n(context).pw_hint_lyrics, _toggleLyrics),
            ],
          ),
        ],
      ),
    );
  }

  /// Desktop / tablet: large cover, title, seek bar, mode pills and transport.
  Widget _buildWide(
    PlayerColors colors,
    RawContent track,
    bool hasTrack,
    bool hasCover,
    bool canSkip,
    Duration playTime,
    Duration endTime,
  ) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          if (hasCover) ...[TrackCover(coverUrl: track.albumArt.toString(), size: 150), const SizedBox(width: 28)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleBlock(colors, track, titleStyle),
                const SizedBox(height: 8),
                _seekBar(colors, playTime, endTime, 6),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TogglePill(
                            colors: colors,
                            selected: isShuffle,
                            icon: Icons.shuffle,
                            label: i18n(context).pw_shuffle,
                            tooltip: i18n(context).pw_hint_shuffle,
                            onPressed: _toggleShuffle,
                          ),
                          _TogglePill(
                            colors: colors,
                            selected: isRepeat,
                            icon: Icons.repeat,
                            label: i18n(context).pw_repeat,
                            tooltip: i18n(context).pw_hint_repeat,
                            onPressed: _toggleRepeat,
                          ),
                          _TogglePill(
                            colors: colors,
                            selected: isLyrics,
                            icon: Icons.text_snippet_outlined,
                            label: i18n(context).pw_lyrics,
                            tooltip: i18n(context).pw_hint_lyrics,
                            onPressed: _toggleLyrics,
                          ),
                        ],
                      ),
                    ),
                    _skipButton(colors, Icons.skip_previous, i18n(context).pw_hint_previous, canSkip, previous: true),
                    const SizedBox(width: 8),
                    _playButton(colors, 64, hasTrack),
                    const SizedBox(width: 8),
                    _skipButton(colors, Icons.skip_next, i18n(context).pw_hint_next, canSkip, previous: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Title with artist and album below; tapping it toggles the expansion.
  Widget _titleBlock(PlayerColors colors, RawContent track, TextStyle titleStyle, {bool singleLine = false}) {
    final subtitle = [track.artist, track.album].where((s) => s.isNotEmpty).join(' · ');
    final title = Text(
      track.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: titleStyle.copyWith(color: colors.foreground, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    );
    final sub = Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: colors.muted),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleExpanded,
      child:
          singleLine
              ? Row(children: [Flexible(child: title), const SizedBox(width: 8), Expanded(child: sub)])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, const SizedBox(height: 2), sub]),
    );
  }

  Widget _seekBar(PlayerColors colors, Duration playTime, Duration endTime, double trackHeight) {
    final timeStyle = Theme.of(
      context,
    ).textTheme.bodySmall!.copyWith(color: colors.muted, fontFeatures: const [FontFeature.tabularFigures()]);
    return Row(
      children: [
        Text(playTime.showMS(), style: timeStyle),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: trackHeight,
              activeTrackColor: colors.foreground,
              inactiveTrackColor: colors.track,
              thumbColor: colors.foreground,
              overlayColor: colors.soft,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7, elevation: 0, pressedElevation: 0),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
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
                final newCurrent = Duration(seconds: (value * endTime.inSeconds).toInt());
                ref.read(audioHandlerProvider).seek(newCurrent).then((_) {
                  setState(() {
                    sliderIsMoving = false;
                  });
                });
              },
            ),
          ),
        ),
        Text(endTime.showMS(), style: timeStyle),
      ],
    );
  }

  Widget _playButton(PlayerColors colors, double size, bool hasTrack) {
    return IconButton.filled(
      onPressed: hasTrack ? () => ref.read(playingProvider.notifier).playPauseTrack() : null,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        backgroundColor: colors.strong,
        foregroundColor: colors.onStrong,
        disabledBackgroundColor: colors.strong.withValues(alpha: 0.4),
        disabledForegroundColor: colors.onStrong,
      ),
      icon: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: playPauseController, size: size * 0.48),
      tooltip: i18n(context).pw_hint_play_pause,
    );
  }

  Widget _skipButton(PlayerColors colors, IconData icon, String tooltip, bool enabled, {required bool previous}) {
    final player = ref.read(playingProvider.notifier);
    return IconButton(
      onPressed: enabled ? (previous ? player.playPreviousTrack : player.playNextTrack) : null,
      color: colors.foreground,
      icon: Icon(icon, size: 30),
      tooltip: tooltip,
    );
  }

  Widget _toggleIcon(PlayerColors colors, bool selected, IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      isSelected: selected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: selected ? colors.foreground : colors.muted,
        backgroundColor: selected ? colors.soft : Colors.transparent,
      ),
      icon: Icon(icon, size: 22),
      tooltip: tooltip,
    );
  }
}

/// Labelled on/off button for shuffle, repeat and lyrics in the wide layout.
class _TogglePill extends StatelessWidget {
  final PlayerColors colors;
  final bool selected;
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _TogglePill({
    required this.colors,
    required this.selected,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: selected,
      child: Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: selected ? colors.onStrong : colors.muted,
            backgroundColor: selected ? colors.strong : Colors.transparent,
            side: BorderSide(color: selected ? colors.strong : colors.muted.withValues(alpha: 0.4)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(0, 40),
          ),
        ),
      ),
    );
  }
}

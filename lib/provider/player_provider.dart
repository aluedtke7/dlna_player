import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/model/lru_list.dart';
import 'package:dlna_player/model/lyrics.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/service/events.dart';
import 'package:dlna_player/service/genius_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _lruList = LRUList<String>([], prefsKey: PrefKeys.lruListPrefsKey);
final GeniusHelper geniusHelper = GeniusHelper();

// Global handler instance, initialized in main()
late DlnaAudioHandler audioHandler;

final audioHandlerProvider = Provider<DlnaAudioHandler>((ref) => audioHandler);

// ---------------------------------------------------------------------
// Simple Audio Handler wrapper around just_audio
// ---------------------------------------------------------------------
class DlnaAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  List<RawContent> _currentPlaylist = [];

  DlnaAudioHandler() {
    _init();
  }

  // Helper to get a local content:// URI for album art (cached via FileProvider)
  Future<Uri?> _getLocalArtUri(String? url) async {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final cacheDir = await getTemporaryDirectory();
    final albumArtDir = Directory('${cacheDir.path}/album_art');
    if (!await albumArtDir.exists()) {
      await albumArtDir.create(recursive: true);
    }

    // Safe filename: base64url(url) + original extension
    final encoded = base64Url.encode(utf8.encode(url)).replaceAll('=', '');
    // Get extension from uri.path
    final path = uri.path;
    final ext = path.contains('.') ? path.substring(path.lastIndexOf('.')) : '';
    final filename = '$encoded$ext';

    final file = File('${albumArtDir.path}/$filename');
    if (await file.exists()) {
      return Uri.parse(
        'content://de.luedtke.dlna_player.fileprovider/album_art/$filename',
      );
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        return Uri.parse(
          'content://de.luedtke.dlna_player.fileprovider/album_art/$filename',
        );
      }
    } catch (_) {}
    return null;
  }

  Future<void> _init() async {
    // Forward player events to AudioService playbackState
    _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: _getControls(),
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          processingState: _mapProcessingState(_player.processingState),
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
        ),
      );
    });

    // Update mediaItem when current index changes
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Update mediaItem.duration when player duration becomes known
    _player.durationStream.listen((duration) {
      if (duration != null && mediaItem.value != null) {
        final current = mediaItem.value!;
        if (current.duration != duration) {
          mediaItem.add(current.copyWith(duration: duration));
        }
      }
    });

    // Initial playback state
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
        queueIndex: 0,
      ),
    );
  }

  List<MediaControl> _getControls() {
    if (_player.playing) {
      return const [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.stop,
        MediaControl.skipToNext,
      ];
    } else {
      return const [
        MediaControl.skipToPrevious,
        MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ];
    }
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // Parse DLNA duration string (HH:MM:SS.mmm or MM:SS.mmm or seconds) into Duration
  Duration? _parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    final parts = durationStr.split(':');
    try {
      if (parts.length == 3) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = double.parse(parts[2]).toInt();
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      } else if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = double.parse(parts[1]).toInt();
        return Duration(minutes: minutes, seconds: seconds);
      } else if (parts.length == 1) {
        final secs = double.parse(parts[0]).toInt();
        return Duration(seconds: secs);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Set playlist (list of tracks)
  Future<void> setPlaylist(List<RawContent> tracks) async {
    _currentPlaylist = List.from(tracks);
    // Build MediaItems quickly (no blocking album art download)
    final List<MediaItem> mediaItems =
        tracks.map((track) {
          final dur = _parseDuration(track.duration);
          return MediaItem(
            id: track.id,
            title: track.title,
            artist: track.artist,
            album: track.album,
            duration: dur,
            artUri: null, // will be set later
            extras: {
              'trackUrl': track.trackUrl!,
              'originalAlbumArt': track.albumArt,
            },
          );
        }).toList();

    // Set queue immediately
    queue.add(mediaItems);

    final audioSources =
        mediaItems.map((item) {
          return AudioSource.uri(
            Uri.parse(item.extras!['trackUrl'] as String),
            tag: item,
          );
        }).toList();

    await _player.setAudioSources(
      audioSources,
      initialIndex: 0,
      initialPosition: Duration.zero,
    );

    // After setting up playback, kick off background album art downloads
    for (int i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      final artUrl = track.albumArt;
      if (artUrl != null && artUrl.isNotEmpty) {
        _getLocalArtUri(artUrl).then((uri) {
          if (uri != null) {
            // Update the specific MediaItem in the current queue
            final updated = List<MediaItem>.from(queue.value);
            if (i < updated.length) {
              updated[i] = updated[i].copyWith(artUri: uri);
              queue.add(updated);
            }
          }
        });
      }
    }
  }

  void setShuffle(bool shuffle) {
    _player.setShuffleModeEnabled(shuffle);
  }

  Future<void> playIndex(int index) async {
    if (index >= 0 && index < (queue.value.length)) {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
    }
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  void setRepeat(bool repeat) {
    _player.setLoopMode(repeat ? LoopMode.all : LoopMode.off);
  }

  // Get current playlist as RawContent
  List<RawContent> get currentPlaylist => List.unmodifiable(_currentPlaylist);

  // Get current index from player
  int get currentIndex => _player.currentIndex ?? 0;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToQueueItem(int index) => playIndex(index);

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  // Expose streams
  Stream<PlaybackState> get playbackStateStream => playbackState.stream;

  Stream<MediaItem?> get mediaItemStream => mediaItem.stream;

  Stream<List<MediaItem>> get queueStream => queue.stream;

  Stream<Duration> get positionStream => _player.positionStream;

  Stream<Duration?> get durationStream => _player.durationStream;

  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  Stream<bool> get playerPlayingStream => _player.playingStream;
}

// ---------------------------------------------------------------------
// Provider for LRU list
// ---------------------------------------------------------------------
final lruListProvider = Provider<LRUList<String>>((ref) => _lruList);

// ---------------------------------------------------------------------
// Provider for current track
// ---------------------------------------------------------------------
class TrackNotifier extends Notifier<RawContent> {
  StreamSubscription? _subscription;

  @override
  RawContent build() {
    final handler = ref.watch(audioHandlerProvider);

    _subscription = handler.mediaItemStream.listen((item) {
      if (item != null) {
        final originalAlbumArt = item.extras?['originalAlbumArt'] as String?;
        state = RawContent(
          id: item.id,
          title: item.title,
          artist: item.artist ?? '',
          album: item.album ?? '',
          trackUrl: item.extras?['trackUrl'] as String?,
          albumArt: originalAlbumArt,
        );
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return RawContent();
  }

  void setTrack(RawContent newTrack) {
    state = newTrack;
  }
}

final trackProvider = NotifierProvider<TrackNotifier, RawContent>(
  () => TrackNotifier(),
);

// ---------------------------------------------------------------------
// Provider for playlist
// ---------------------------------------------------------------------
class PlaylistNotifier extends Notifier<List<RawContent>> {
  StreamSubscription? _subscription;

  @override
  List<RawContent> build() {
    final handler = ref.watch(audioHandlerProvider);

    // Convert MediaItem list to RawContent list
    List<RawContent> convert(List<MediaItem> items) {
      return items.map((item) {
        final originalAlbumArt = item.extras?['originalAlbumArt'] as String?;
        return RawContent(
          id: item.id,
          title: item.title,
          artist: item.artist ?? '',
          album: item.album ?? '',
          trackUrl: item.extras!['trackUrl'] as String? ?? '',
          albumArt: originalAlbumArt,
          duration: (item.duration?.inSeconds ?? 0).toString(),
        );
      }).toList();
    }

    // Set initial state
    state = convert(handler.queue.value);

    // Listen for queue changes
    _subscription = handler.queueStream.listen((queue) {
      state = convert(queue);
    });

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  Future<void> setPlaylist(List<RawContent> newPlaylist) async {
    state = newPlaylist;
    final handler = ref.read(audioHandlerProvider);
    final currentQueue = handler.queue.value;

    // Compare current queue with new playlist by track IDs to avoid unnecessary reset
    if (currentQueue.length == newPlaylist.length) {
      bool identical = true;
      for (int i = 0; i < currentQueue.length; i++) {
        if (currentQueue[i].id != newPlaylist[i].id) {
          identical = false;
          break;
        }
      }
      if (identical) {
        // Playlist already matches, skip resetting the player
        return;
      }
    }
    await handler.setPlaylist(newPlaylist);
  }
}

final playlistProvider = NotifierProvider<PlaylistNotifier, List<RawContent>>(
  () => PlaylistNotifier(),
);

// ---------------------------------------------------------------------
// Provider for playlist index
// ---------------------------------------------------------------------
class PlaylistIndexNotifier extends Notifier<int> {
  StreamSubscription? _subscription;

  @override
  int build() {
    final handler = ref.watch(audioHandlerProvider);
    state = handler.currentIndex;

    _subscription = handler.currentIndexStream.listen((index) {
      state = index ?? 0;
    });

    ref.onDispose(() => _subscription?.cancel());

    return state;
  }

  void setIndex(int newIndex) {
    state = newIndex;
    ref.read(audioHandlerProvider).skipToQueueItem(newIndex);
  }
}

final playlistIndexProvider = NotifierProvider<PlaylistIndexNotifier, int>(
  () => PlaylistIndexNotifier(),
);

// ---------------------------------------------------------------------
// Provider for play state
// ---------------------------------------------------------------------
class PlayingNotifier extends Notifier<bool> {
  StreamSubscription? _playingSubscription;

  @override
  bool build() {
    final handler = ref.watch(audioHandlerProvider);

    // Sync current modes to handler
    handler.setShuffle(ref.read(shuffleModeProvider));
    handler.setRepeat(ref.read(repeatModeProvider));

    // Listen for changes
    ref.listen<bool>(shuffleModeProvider, (prev, next) {
      handler.setShuffle(next);
    });
    ref.listen<bool>(repeatModeProvider, (prev, next) {
      handler.setRepeat(next);
    });

    _playingSubscription = handler.playerPlayingStream.listen((playing) {
      state = playing;
    });

    ref.onDispose(() {
      _playingSubscription?.cancel();
    });

    return false;
  }

  void playPauseTrack() {
    final handler = ref.read(audioHandlerProvider);
    if (state) {
      handler.pause();
    } else {
      handler.play();
    }
  }

  Future<void> handleError(String err) async {
    ref.read(errorProvider.notifier).setError(err.toString());
  }

  // Complex playlist navigation with shuffle/repeat/LRU
  void playNextTrack() {
    ref.read(audioHandlerProvider).skipToNext();
  }

  void playPreviousTrack() {
    ref.read(audioHandlerProvider).skipToPrevious();
  }

  Future<void> getLyrics() async {
    ref
        .read(lyricsProvider.notifier)
        .setLyrics(const Lyrics(LyricsState.unknown));
    if (ref.read(showLyricsProvider)) {
      ref
          .read(lyricsProvider.notifier)
          .setLyrics(const Lyrics(LyricsState.loading));
      final track = ref.read(trackProvider);
      final lyrics = await geniusHelper.searchLyrics(track.artist, track.title);
      if (lyrics.text.isEmpty) {
        ref
            .read(lyricsProvider.notifier)
            .setLyrics(const Lyrics(LyricsState.empty));
      } else {
        ref
            .read(lyricsProvider.notifier)
            .setLyrics(Lyrics(LyricsState.success, lyrics.text));
      }
    }
  }

  Future<void> updateGeniusToken(String geniusApiToken) async {
    geniusHelper.setToken(geniusApiToken);
  }

  void skipForward() {
    final handler = ref.read(audioHandlerProvider);
    final currentPos = handler.playbackState.value.updatePosition;
    handler.seek(currentPos + const Duration(seconds: 10));
  }

  void skipBackward() {
    final handler = ref.read(audioHandlerProvider);
    final currentPos = handler.playbackState.value.updatePosition;
    final newPos =
        currentPos > const Duration(seconds: 10)
            ? currentPos - const Duration(seconds: 10)
            : Duration.zero;
    handler.seek(newPos);
  }
}

final playingProvider = NotifierProvider<PlayingNotifier, bool>(
  () => PlayingNotifier(),
);

// ----------------------------------------------------------------------
// Provider for play time (position)
// ----------------------------------------------------------------------
class PlayTimeNotifier extends Notifier<Duration> {
  StreamSubscription? _subscription;

  @override
  Duration build() {
    final handler = ref.watch(audioHandlerProvider);

    _subscription = handler.positionStream.listen((position) {
      state = position;
    });

    ref.onDispose(() => _subscription?.cancel());

    return Duration.zero;
  }
}

final playTimeProvider = NotifierProvider<PlayTimeNotifier, Duration>(
  () => PlayTimeNotifier(),
);

// ---------------------------------------------------------------------
// Provider for track duration
// ---------------------------------------------------------------------
class EndTimeNotifier extends Notifier<Duration> {
  StreamSubscription? _subscription;

  @override
  Duration build() {
    final handler = ref.watch(audioHandlerProvider);

    _subscription = handler.durationStream.listen((duration) {
      if (duration != null) {
        state = duration;
      }
    });

    ref.onDispose(() => _subscription?.cancel());

    return Duration.zero;
  }
}

final endTimeProvider = NotifierProvider<EndTimeNotifier, Duration>(
  () => EndTimeNotifier(),
);

// ---------------------------------------------------------------------
// Provider for volume
// ---------------------------------------------------------------------
class VolumeNotifier extends Notifier<double> {
  @override
  double build() {
    final handler = ref.watch(audioHandlerProvider);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      SharedPreferences.getInstance().then((sp) {
        final volume = sp.getDouble(PrefKeys.volumePrefsKey) ?? 0.5;
        state = volume;
        handler.setVolume(volume);
        debugPrint('VolumeNotifier ${volume.showPercent()}');
      });
    } else {
      state = 1.0;
    }
    return 0.5;
  }

  void increaseVolume() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final current = state;
      double newVolume;
      if (current < 0.16) {
        newVolume = min(current + 0.01, 1.0);
      } else {
        newVolume = min(current + 0.05, 1.0);
      }
      state = newVolume;
      ref.read(audioHandlerProvider).setVolume(newVolume);
      eventBus.fire(VolumeChangedEvent(newVolume));
      SharedPreferences.getInstance().then((sp) {
        sp.setDouble(PrefKeys.volumePrefsKey, newVolume);
      });
    }
  }

  void decreaseVolume() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final current = state;
      double newVolume;
      if (current < 0.16) {
        newVolume = max(current - 0.01, 0.0);
      } else {
        newVolume = max(current - 0.05, 0.0);
      }
      state = newVolume;
      ref.read(audioHandlerProvider).setVolume(newVolume);
      eventBus.fire(VolumeChangedEvent(newVolume));
      SharedPreferences.getInstance().then((sp) {
        sp.setDouble(PrefKeys.volumePrefsKey, newVolume);
      });
    }
  }
}

final volumeProvider = NotifierProvider<VolumeNotifier, double>(
  () => VolumeNotifier(),
);

// ---------------------------------------------------------------------
// Provider for errors
// ---------------------------------------------------------------------
class ErrorNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setError(String error) {
    state = error;
  }
}

final errorProvider = NotifierProvider<ErrorNotifier, String>(
  () => ErrorNotifier(),
);

// ---------------------------------------------------------------------
// Lyrics Notifier
// ---------------------------------------------------------------------
class LyricsNotifier extends Notifier<Lyrics> {
  @override
  Lyrics build() => const Lyrics(LyricsState.unknown);

  void setLyrics(Lyrics newLyrics) {
    state = newLyrics;
  }
}

final lyricsProvider = NotifierProvider<LyricsNotifier, Lyrics>(
  () => LyricsNotifier(),
);

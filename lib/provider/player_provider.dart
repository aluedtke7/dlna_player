import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

final _player = AudioPlayer();
final _lruList = LRUList<String>([], prefsKey: PrefKeys.lruListPrefsKey);
final List<StreamSubscription> _subscriptions = [];
final GeniusHelper geniusHelper = GeniusHelper();
bool playerInitialized = false;

// ---------------------------------------------------------------------
// provider to access AudioPlayer
// ---------------------------------------------------------------------
final playerProvider = Provider((ref) {
  if (!playerInitialized) {
    playerInitialized = true;
    _player.setReleaseMode(ReleaseMode.stop);
    if (Platform.isAndroid) {
      _player.setAudioContext(AudioContext(android: const AudioContextAndroid(stayAwake: true)));
    }
  }
  return _player;
});

// ---------------------------------------------------------------------
// provider for handling changes in tracks
// ---------------------------------------------------------------------
class TrackNotifier extends Notifier<RawContent> {
  @override
  RawContent build() => RawContent();

  void setTrack(RawContent newTrack) {
    state = newTrack;
  }
}

final trackProvider = NotifierProvider<TrackNotifier, RawContent>(() => TrackNotifier());

// ---------------------------------------------------------------------
// provider for handling the playlist
// ---------------------------------------------------------------------
class PlaylistNotifier extends Notifier<List<RawContent>> {
  @override
  List<RawContent> build() => [];

  void setPlaylist(List<RawContent> newPlaylist) {
    state = newPlaylist;
  }
}

final playlistProvider = NotifierProvider<PlaylistNotifier, List<RawContent>>(() => PlaylistNotifier());

// ---------------------------------------------------------------------
// provider for handling the playlist index (current track index)
// ---------------------------------------------------------------------
class LyricsNotifier extends Notifier<Lyrics> {
  @override
  Lyrics build() => const Lyrics(LyricsState.unknown);

  void setLyrics(Lyrics newLyrics) {
    state = newLyrics;
  }
}

final lyricsProvider = NotifierProvider<LyricsNotifier, Lyrics>(() => LyricsNotifier());

// ---------------------------------------------------------------------
// provider for handling the playlist index (current track index)
// ---------------------------------------------------------------------
class PlaylistIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int newIndex) {
    state = newIndex;
  }
}

final playlistIndexProvider = NotifierProvider<PlaylistIndexNotifier, int>(() => PlaylistIndexNotifier());

// ---------------------------------------------------------------------
// provider to access LRUList
// ---------------------------------------------------------------------
final lruListProvider = Provider((ref) => _lruList);

// ---------------------------------------------------------------------
// provider for handling changes in play state
// ---------------------------------------------------------------------
class PlayingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _subscriptions.add(
      _player.onPlayerStateChanged.listen((event) {
        switch (event) {
          case PlayerState.playing:
            state = true;
            break;
          case PlayerState.paused:
            state = false;
            break;
          case PlayerState.stopped:
            state = false;
            break;
          case PlayerState.completed:
            state = false;
            playNextTrack();
            break;
          default:
            state = false;
            break;
        }
      }),
    );
    return false;
  }

  void playPauseTrack() {
    final trackRef = ref.read(trackProvider);
    final playTimeRef = ref.read(playTimeProvider);
    final endTimeRef = ref.read(endTimeProvider);
    final player = ref.read(playerProvider);
    if (state) {
      player.pause();
    } else {
      if (playTimeRef.inSeconds == endTimeRef.inSeconds) {
        player.play(UrlSource(trackRef.trackUrl!), mode: PlayerMode.mediaPlayer);
        ref.read(lruListProvider).add(trackRef.id);
      } else {
        player.resume();
      }
    }
  }

  Future<void> handleError(String err) async {
    ref.read(errorProvider.notifier).setError(err.toString());
  }

  void playNextTrack() {
    var doPlay = false;
    var currentIdx = 0;
    var lruList = ref.read(lruListProvider);
    var playlist = ref.read(playlistProvider);
    final listSize = playlist.length;
    if (ref.read(shuffleModeProvider)) {
      if (listSize > 1) {
        // Check list of recently played tracks (LRU) and select other random value if found in list.
        // If all tracks have been played, remove playlist entries from LRU list if repeat mode is on, otherwise stop.
        // In order to check the whole playlist, it's necessary to have a LRU list of the same size,
        // otherwise we can't determine that all tracks have been played and we stay in repeat mode
        // even if this is disabled. With other words: when the playlist is larger than the LRU list,
        // the playing will never stop.
        var count = 0;
        final List<int> tries = [];
        do {
          currentIdx = Random().nextInt(listSize);
          if (!tries.contains(currentIdx)) {
            tries.add(currentIdx);
            count++;
          }
        } while (count < playlist.length && lruList.contains(playlist[currentIdx].id));
        if (count >= playlist.length) {
          if (ref.read(repeatModeProvider)) {
            // remove content of playlist from LRU list to allow playing these tracks again
            lruList.removeList(playlist.map((e) => e.id).toList());
            doPlay = true;
          }
        } else {
          doPlay = true;
        }
      } else {
        if (ref.read(repeatModeProvider)) {
          doPlay = true;
        }
      }
    } else {
      currentIdx = ref.read(playlistIndexProvider) + 1;
      if (currentIdx >= listSize) {
        currentIdx = 0;
      }
      // do not repeat if repeat mode is off
      if (currentIdx != 0 || ref.read(repeatModeProvider)) {
        doPlay = true;
      }
    }
    if (doPlay) {
      ref.read(playlistIndexProvider.notifier).setIndex(currentIdx);
      ref.read(trackProvider.notifier).setTrack(playlist[currentIdx]);
      ref
          .read(playerProvider)
          .play(UrlSource(playlist[currentIdx].trackUrl!), mode: PlayerMode.mediaPlayer)
          .then((_) {
        lruList.add(playlist[currentIdx].id);
        getLyrics();
      })
          .onError((err, _) {
        debugPrint('doPlay: AudioPlayers Exception $err');
        handleError(err.toString());
      });
    }
  }

  void playPreviousTrack() {
    final trackRef = ref.read(trackProvider);
    final playlistRef = ref.read(playlistProvider);
    if (ref.read(shuffleModeProvider)) {
      // find last played track in LRU list and select it
      var lruList = ref.read(lruListProvider);
      var idx = lruList.indexOf(trackRef.id);
      if (idx > 0) {
        idx--;
      } else {
        idx = lruList.length() - 1;
      }
      // since the LRU list contains only ids, we have to locate the id in the playlist
      var currentIdx = 0;
      for (var i = 0; i < playlistRef.length; i++) {
        final track = playlistRef[i];
        if (track.id == lruList.list[idx]) {
          currentIdx = i;
          break;
        }
      }
      ref.read(playlistIndexProvider.notifier).setIndex(currentIdx);
      ref.read(trackProvider.notifier).setTrack(playlistRef[currentIdx]);
      ref
          .read(playerProvider)
          .play(UrlSource(playlistRef[currentIdx].trackUrl!), mode: PlayerMode.mediaPlayer)
          .then((_) {
        getLyrics();
      })
          .onError((err, _) {
        debugPrint('shuffleMode: AudioPlayers Exception $err');
        handleError(err.toString());
      });
    } else {
      // just use track of last index
      final listSize = playlistRef.length;
      if (listSize > 0) {
        int currentIdx = ref.read(playlistIndexProvider) - 1;
        if (currentIdx < 0) {
          currentIdx = listSize - 1;
        }
        ref.read(playlistIndexProvider.notifier).setIndex(currentIdx);
        ref.read(trackProvider.notifier).setTrack(playlistRef[currentIdx]);
        ref
            .read(playerProvider)
            .play(UrlSource(playlistRef[currentIdx].trackUrl!), mode: PlayerMode.mediaPlayer)
            .then((_) {
          getLyrics();
        })
            .onError((err, _) {
          debugPrint('normalMode: AudioPlayers Exception $err');
          handleError(err.toString());
        });
      }
    }
  }

  Future<void> getLyrics() async {
    // clear previous lyrics
    ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.unknown));
    if (ref.read(showLyricsProvider)) {
      ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.loading));
      final track = ref.read(trackProvider);
      final lyrics = await geniusHelper.searchLyrics(track.artist, track.title);
      if (lyrics.text.isEmpty) {
        ref.read(lyricsProvider.notifier).setLyrics(const Lyrics(LyricsState.empty));
      } else {
        ref.read(lyricsProvider.notifier).setLyrics(Lyrics(LyricsState.success, lyrics.text));
      }
    }
  }

  Future<void> updateGeniusToken(String geniusApiToken) async {
    geniusHelper.setToken(geniusApiToken);
  }

  Duration _clampDuration(Duration position, Duration max) {
    if (position.isNegative) {
      return Duration.zero;
    } else if (position.compareTo(max) > 0) {
      return max;
    }
    return position;
  }

  void _skip(bool backward) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _player.getCurrentPosition().then((currentPos) {
        late Duration newPosition;
        if (backward) {
          newPosition = (currentPos ?? Duration.zero) - Duration(seconds: 10);
        } else {
          newPosition = (currentPos ?? Duration.zero) + Duration(seconds: 10);
        }
        _player.seek(_clampDuration(newPosition, ref.read(endTimeProvider)));
      });
    }
  }

  void skipForward() {
    _skip(false);
  }

  void skipBackward() {
    _skip(true);
  }
}

final playingProvider = NotifierProvider<PlayingNotifier, bool>(() => PlayingNotifier());

// ----------------------------------------------------------------------
// provider for handling changes in play time (current position in track)
// ----------------------------------------------------------------------
class PlayTimeNotifier extends Notifier<Duration> {
  @override
  Duration build() {
    _subscriptions.add(
      _player.onPositionChanged.listen((event) {
        state = event;
      }),
    );
    return Duration.zero;
  }
}

final playTimeProvider = NotifierProvider<PlayTimeNotifier, Duration>(() => PlayTimeNotifier());

// ---------------------------------------------------------------------
// provider for handling changes in track duration
// ---------------------------------------------------------------------
class EndTimeNotifier extends Notifier<Duration> {
  @override
  Duration build() {
    _subscriptions.add(
      _player.onDurationChanged.listen((duration) {
        state = duration;
      }),
    );
    return Duration.zero;
  }
}

final endTimeProvider = NotifierProvider<EndTimeNotifier, Duration>(() => EndTimeNotifier());

// ---------------------------------------------------------------------
// provider for handling changes in volume
// ---------------------------------------------------------------------
class VolumeNotifier extends Notifier<double> {
  @override
  double build() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      SharedPreferences.getInstance().then((sp) {
        state = sp.getDouble(PrefKeys.volumePrefsKey) ?? 0.5;
        _player.setVolume(state.toDouble());
        debugPrint('VolumeNotifier ${state.showPercent()}');
      });
    }
    return 0;
  }

  void increaseVolume() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (_player.volume < 0.16) {
        state = min(_player.volume + 0.01, 1.0);
      } else {
        state = min(_player.volume + 0.05, 1.0);
      }
      _player.setVolume(state.toDouble());
      // debugPrint('Volume increased: ${state.showPercent()}');
      eventBus.fire(VolumeChangedEvent(state));
      SharedPreferences.getInstance().then((sp) {
        sp.setDouble(PrefKeys.volumePrefsKey, state);
      });
    }
  }

  void decreaseVolume() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (_player.volume < 0.16) {
        state = max(_player.volume - 0.01, 0.0);
      } else {
        state = max(_player.volume - 0.05, 0.0);
      }
      _player.setVolume(state.toDouble());
      // debugPrint('Volume decreased: ${state.showPercent()}');
      eventBus.fire(VolumeChangedEvent(state));
      SharedPreferences.getInstance().then((sp) {
        sp.setDouble(PrefKeys.volumePrefsKey, state);
      });
    }
  }
}

final volumeProvider = NotifierProvider<VolumeNotifier, double>(() => VolumeNotifier());

// ---------------------------------------------------------------------
// provider for errors that happened while playing music
// ---------------------------------------------------------------------
class ErrorNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setError(String error) {
    state = error;
  }
}

final errorProvider = NotifierProvider<ErrorNotifier, String>(() => ErrorNotifier());
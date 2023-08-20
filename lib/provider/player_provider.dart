import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:dlna_player/model/lru_list.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _player = AudioPlayer();
final _lruList = LRUList<String>([], prefsKey: PrefKeys.lruListPrefsKey);
final List<StreamSubscription> _subsciptions = [];

// ---------------------------------------------------------------------
// provider to access AudioPlayer
// ---------------------------------------------------------------------
final playerProvider = Provider(
  (ref) {
    return _player;
  },
);

// ---------------------------------------------------------------------
// provider for handling changes in tracks
// ---------------------------------------------------------------------
class TrackNotifier extends StateNotifier<RawContent> {
  TrackNotifier() : super(RawContent());

  void setTrack(RawContent newTrack) {
    state = newTrack;
  }
}

final trackProvider = StateNotifierProvider<TrackNotifier, RawContent>((ref) => TrackNotifier());

// ---------------------------------------------------------------------
// provider for handling the playlist
// ---------------------------------------------------------------------
class PlaylistNotifier extends StateNotifier<List<RawContent>> {
  PlaylistNotifier() : super([]);

  void setPlaylist(List<RawContent> newPlaylist) {
    state = newPlaylist;
  }
}

final playlistProvider = StateNotifierProvider<PlaylistNotifier, List<RawContent>>((ref) => PlaylistNotifier());

// ---------------------------------------------------------------------
// provider for handling the playlist index (current track index)
// ---------------------------------------------------------------------
class PlaylistIndexNotifier extends StateNotifier<int> {
  PlaylistIndexNotifier() : super(0);

  void setIndex(int newIndex) {
    state = newIndex;
  }
}

final playlistIndexProvider = StateNotifierProvider<PlaylistIndexNotifier, int>((ref) => PlaylistIndexNotifier());

// ---------------------------------------------------------------------
// provider to access LRUList
// ---------------------------------------------------------------------
final lruListProvider = Provider(
  (ref) => _lruList,
);

// ---------------------------------------------------------------------
// provider for handling changes in play state
// ---------------------------------------------------------------------
class PlayingNotifier extends StateNotifier<bool> {
  final Ref ref;

  void playPauseTrack() {
    final trackRef = ref.read(trackProvider);
    final playTimeRef = ref.read(playTimeProvider);
    final endTimeRef = ref.read(endTimeProvider);
    final player = ref.read(playerProvider);
    if (state) {
      player.pause();
    } else {
      if (playTimeRef.inSeconds == endTimeRef.inSeconds) {
        player.play(UrlSource(trackRef.trackUrl!));
        ref.read(lruListProvider).add(trackRef.id);
      } else {
        player.resume();
      }
    }
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
        // In order to check the whole playlist, it's neccessary to have a LRU list of the same size,
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
      ref.read(playerProvider).play(UrlSource(playlist[currentIdx].trackUrl!));
      lruList.add(playlist[currentIdx].id);
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
      ref.read(playerProvider).play(UrlSource(playlistRef[currentIdx].trackUrl!));
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
        ref.read(playerProvider).play(UrlSource(playlistRef[currentIdx].trackUrl!));
      }
    }
  }

  PlayingNotifier(this.ref) : super(false) {
    _subsciptions.add(_player.onPlayerStateChanged.listen((event) {
      switch (event) {
        case PlayerState.playing:
          // debugPrint('Provider - Player playing.');
          state = true;
          break;
        case PlayerState.paused:
          // debugPrint('Provider - Player paused.');
          state = false;
          break;
        case PlayerState.stopped:
          // debugPrint('Provider - Player stopped.');
          state = false;
          break;
        case PlayerState.completed:
          // debugPrint('Provider - Player completed.');
          state = false;
          playNextTrack();
          break;
        default:
          break;
      }
    }));
  }
}

final playingProvider = StateNotifierProvider<PlayingNotifier, bool>((ref) => PlayingNotifier(ref));

// ---------------------------------------------------------------------
// provider for handling changes in play time (current position in track)
// ---------------------------------------------------------------------
class PlayTimeNotifier extends StateNotifier<Duration> {
  PlayTimeNotifier() : super(Duration.zero) {
    _subsciptions.add(_player.onPositionChanged.listen((event) {
      state = event;
    }));
  }
}

final playTimeProvider = StateNotifierProvider<PlayTimeNotifier, Duration>((ref) => PlayTimeNotifier());

// ---------------------------------------------------------------------
// provider for handling changes in track duration
// ---------------------------------------------------------------------
class EndTimeNotifier extends StateNotifier<Duration> {
  EndTimeNotifier() : super(Duration.zero) {
    _subsciptions.add(_player.onDurationChanged.listen((event) {
      // debugPrint('Provider - new duration: ${event.showMS()}');
      state = event;
    }));
  }
}

final endTimeProvider = StateNotifierProvider<EndTimeNotifier, Duration>((ref) => EndTimeNotifier());

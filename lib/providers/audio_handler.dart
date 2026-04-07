import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

// Global handler instance, initialized in main()
late DlnaAudioHandler audioHandler;

final audioHandlerProvider = Provider<DlnaAudioHandler>((ref) => audioHandler);

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
      try {
        final idx = _player.currentIndex;
        if (idx == null || idx < 0 || idx >= queue.value.length) return;
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
            queueIndex: idx,
          ),
        );
      } catch (e) {
        // Ignore errors during playback state updates
      }
    });

    // Update mediaItem when current index changes, and load album art on demand
    _player.currentIndexStream.listen((index) {
      if (index != null &&
          index >= 0 &&
          queue.value.isNotEmpty &&
          index < queue.value.length) {
        final item = queue.value[index];
        mediaItem.add(item);

        // Load album art if not already loaded
        final currentArtUri = item.artUri;
        final originalAlbumArt = item.extras?['originalAlbumArt'] as String?;
        if (currentArtUri == null &&
            originalAlbumArt != null &&
            originalAlbumArt.isNotEmpty) {
          _getLocalArtUri(originalAlbumArt).then((uri) {
            if (uri != null) {
              final updated = item.copyWith(artUri: uri);
              // Update the queue item so UI and notification show the art
              final updatedQueue = List<MediaItem>.from(queue.value);
              if (index < updatedQueue.length) {
                updatedQueue[index] = updated;
                queue.add(updatedQueue);
              }
              // Also update current mediaItem if still the same track
              if (mediaItem.value?.id == item.id) {
                mediaItem.add(updated);
              }
            }
          });
        }
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
            artUri: null,
            // will be set later
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
  int get currentIndex => _player.currentIndex ?? -1;

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

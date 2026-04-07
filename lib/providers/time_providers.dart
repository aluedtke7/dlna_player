import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/providers/audio_handler.dart';

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

final playTimeProvider = NotifierProvider<PlayTimeNotifier, Duration>(() => PlayTimeNotifier());

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

final endTimeProvider = NotifierProvider<EndTimeNotifier, Duration>(() => EndTimeNotifier());

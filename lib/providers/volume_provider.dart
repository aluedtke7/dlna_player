import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dlna_player/component/extensions.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/providers/audio_handler.dart';
import 'package:dlna_player/service/events.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

final volumeProvider = NotifierProvider<VolumeNotifier, double>(() => VolumeNotifier());

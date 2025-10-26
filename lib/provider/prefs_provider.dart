import 'package:dlna_player/model/lru_list.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _lastServerList = LRUList<String>([], maxLength: 5, prefsKey: PrefKeys.lastUsedServerUrlPrefsKey);

// ---------------------------------------------------------------------
// provider for handling PlayerWidget expansion state changes
// ---------------------------------------------------------------------
class PlayerWidgetExpansionNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setExpansion(bool isExpanded) {
    state = isExpanded;
  }
}

final playerWidgetExpansionProvider = NotifierProvider<PlayerWidgetExpansionNotifier, bool>(() => PlayerWidgetExpansionNotifier());

// ---------------------------------------------------------------------
// provider for handling the shuffle mode state
// ---------------------------------------------------------------------
class ShuffleModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setShuffle(bool shuffle) {
    state = shuffle;
  }
}

final shuffleModeProvider = NotifierProvider<ShuffleModeNotifier, bool>(() => ShuffleModeNotifier());

// ---------------------------------------------------------------------
// provider for handling repeat mode state
// ---------------------------------------------------------------------
class RepeatModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRepeat(bool repeat) {
    state = repeat;
  }
}

final repeatModeProvider = NotifierProvider<RepeatModeNotifier, bool>(() => RepeatModeNotifier());

// ---------------------------------------------------------------------
// provider for handling show lyrics state
// ---------------------------------------------------------------------
class ShowLyricsNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setShowLyrics(bool showLyrics) {
    state = showLyrics;
  }
}

final showLyricsProvider = NotifierProvider<ShowLyricsNotifier, bool>(() => ShowLyricsNotifier());

// ---------------------------------------------------------------------
// provider to access Last Server List
// ---------------------------------------------------------------------
final lastServerListProvider = Provider(
      (ref) => _lastServerList,
);

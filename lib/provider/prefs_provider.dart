import 'package:dlna_player/model/lru_list.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _lastServerList = LRUList<String>([], maxLength: 5, prefsKey: PrefKeys.lastUsedServerUrlPrefsKey);

// ---------------------------------------------------------------------
// provider for handling PlayerWidget expansion state changes
// ---------------------------------------------------------------------
final playerWidgetExpansionProvider = StateProvider<bool>((ref) => true);

// ---------------------------------------------------------------------
// provider for handling the shuffle mode state
// ---------------------------------------------------------------------
final shuffleModeProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------
// provider for handling repeat mode state
// ---------------------------------------------------------------------
final repeatModeProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------
// provider for handling show lyrics state
// ---------------------------------------------------------------------
final showLyricsProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------
// provider to access Last Server List
// ---------------------------------------------------------------------
final lastServerListProvider = Provider(
  (ref) => _lastServerList,
);

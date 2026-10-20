import 'package:dlna_player/model/lru_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'last_used_server_url';
  const minidlna = 'http://10.7.7.222:8200/rootDesc.xml';
  const jellyfin = 'http://10.7.7.222:8096/dlna/description.xml';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('setAll keeps every item only once and in order', () {
    final lru = LRUList<String>([], prefsKey: key)..setAll([jellyfin, minidlna, minidlna, minidlna]);
    expect(lru.list, [jellyfin, minidlna]);
  });

  test('setAll replaces the previous content instead of appending', () {
    final lru = LRUList<String>([], prefsKey: key)
      ..setAll([minidlna])
      ..setAll([minidlna, jellyfin]);
    expect(lru.list, [minidlna, jellyfin]);
  });

  test('add removes all older occurrences and saves a list without duplicates', () async {
    final lru = LRUList<String>([jellyfin, minidlna, minidlna, minidlna], maxLength: 5, prefsKey: key);
    lru.add(minidlna);
    expect(lru.list, [jellyfin, minidlna]);

    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(key), [jellyfin, minidlna]);
  });

  test('add moves an existing item to the end and respects maxLength', () {
    final lru = LRUList<String>(['a', 'b', 'c'], maxLength: 3);
    lru.add('a');
    expect(lru.list, ['b', 'c', 'a']);
    lru.add('d');
    expect(lru.list, ['c', 'a', 'd']);
  });
}

import 'package:shared_preferences/shared_preferences.dart';

class LRUList<T> {
  final List<T> list;
  final int maxLength;
  final String prefsKey;

  LRUList(this.list, {this.maxLength = 500, this.prefsKey = ''});

  LRUList.clone(LRUList<T> lruList) : this(lruList.list, maxLength: lruList.maxLength);

  void add(T item) {
    if (item is String && item.isEmpty) {
      // saving empty Strings make no sense
      return;
    }
    // we always remove an existing item (and duplicates of older versions),
    // this enables a skip back (prev) in shuffle mode
    list.removeWhere((element) => element == item);
    list.add(item);
    // ensure that list doesn't grow over the limit
    if (list.length > maxLength) {
      list.removeAt(0);
    }
    saveLruList();
  }

  Future<void> saveLruList() async {
    if (T == String && prefsKey.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList(prefsKey, list as List<String>);
    }
  }

  int indexOf(T item) {
    return list.indexOf(item);
  }

  void clear() {
    list.clear();
  }

  /// Replaces the content with [items], each item only once.
  void setAll(Iterable<T> items) {
    list
      ..clear()
      ..addAll(items.toSet());
  }

  void removeList(List<T> rem) {
    list.removeWhere((element) => rem.contains(element));
  }

  bool contains(T item) {
    return list.contains(item);
  }

  int length() => list.length;
}

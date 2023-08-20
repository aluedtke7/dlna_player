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
    if (list.contains(item)) {
      // we always remove an existing item, this enables a skip back (prev) in shuffle mode
      list.remove(item);
    }
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

  void removeList(List<T> rem) {
    list.removeWhere((element) => rem.contains(element));
  }

  bool contains(T item) {
    return list.contains(item);
  }

  int length() => list.length;
}

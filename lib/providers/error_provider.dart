import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setError(String error) {
    state = error;
  }
}

final errorProvider = NotifierProvider<ErrorNotifier, String>(() => ErrorNotifier());

import 'package:flutter/material.dart';

class SnackbarHelper {
  static Future<void> showSnackbar(BuildContext ctx, String msg, {bool isError = false}) async {
    final bgColor = isError ? Theme.of(ctx).colorScheme.error : Theme.of(ctx).colorScheme.primary;
    final fgStyle = isError ? const TextStyle(color: Colors.white) : TextStyle(color: Theme.of(ctx).cardTheme.color);
    final duration = isError ? const Duration(milliseconds: 5000) : const Duration(milliseconds: 2500);

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: bgColor,
        content: Text(msg, textAlign: TextAlign.center, style: fgStyle),
        duration: duration,
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      ),
    );
  }

  static Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) => showSnackbar(ctx, e.toString(), isError: true);

  static Future<void> showInfoSnackbar(BuildContext ctx, dynamic e) => showSnackbar(ctx, e.toString());
}

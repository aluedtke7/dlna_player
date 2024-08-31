import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:dlna_player/component/i18n_util.dart';

class Statics {
  static Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) async {
    final String msg = e.toString();

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(ctx).colorScheme.error,
        content: Text(
          msg,
          style: TextStyle(color: Theme.of(ctx).colorScheme.onErrorContainer),
        ),
        duration: const Duration(milliseconds: 5000),
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  static Future<void> showInfoSnackbar(BuildContext ctx, dynamic e) async {
    final String msg = e.toString();

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(ctx).colorScheme.primary,
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(ctx).cardTheme.color),
        ),
        duration: const Duration(milliseconds: 2500),
        padding: const EdgeInsets.all(8.0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
      ),
    );
  }

  static BoxDecoration getSimplePageDecoration() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 200, 200, 200).withOpacity(0.9),
    );
  }

  static BoxDecoration getGradientPageDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color.fromARGB(255, 230, 230, 230).withOpacity(0.5),
          const Color.fromARGB(255, 152, 152, 152).withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 1],
      ),
    );
  }

  static Color getSlideBtnBackgroundLight(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.primary.withAlpha(200);
  }

  static Color getSlideBtnBackgroundDark(BuildContext ctx) {
    return Theme.of(ctx).colorScheme.secondary.withAlpha(200);
  }

  static BoxDecoration getGradientDrawerDecoration(BuildContext ctx) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withOpacity(.1),
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.onSurfaceVariant.withAlpha(100),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, 1],
      ),
    );
  }

  static BoxDecoration getSimpleDrawerDecoration(BuildContext ctx) {
    return BoxDecoration(
      color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.surface.withOpacity(.1),
    );
  }

  static BoxDecoration getGradientDrawerHeaderDecoration(BuildContext ctx) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
          ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary.withAlpha(100),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        stops: const [0, 1],
      ),
    );
  }

  static BoxDecoration getSimpleDrawerHeaderDecoration(BuildContext ctx) {
    return BoxDecoration(
      color: ThemeProvider.controllerOf(ctx).theme.data.colorScheme.primary,
    );
  }

  static Future<String?> showSearchDialog(BuildContext context, String title, String initValue) async {
    final controller = TextEditingController();
    controller.text = initValue;

    return showDialog<String?>(
        context: context,
        builder: (ctx) {
          var textFormField = TextFormField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: i18n(context).com_search,
              suffixIcon: IconButton(
                onPressed: () => controller.clear(),
                icon: const Icon(Icons.clear),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            onEditingComplete: () => Navigator.of(ctx).pop(controller.text),
          );

          return AlertDialog(
            title: Text(title),
            content: textFormField,
            actions: <Widget>[
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(i18n(context).com_cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: Text(i18n(context).com_ok),
              ),
            ],
          );
        });
  }

  static Route createAnimPageRoute(Widget page,
      {String? name, Object? argument, bool toRight = false}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // depending on the slide direction, we slide in from left or from right
        var begin = toRight ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        final offsetAnim = animation.drive(tween);
        return SlideTransition(
          position: offsetAnim,
          child: child,
        );
      },
      settings: RouteSettings(arguments: argument, name: name),
    );
  }

  static int tintValue(int value, double factor) => max(0, min((value + ((255 - value) * factor)).round(), 255));

  static Color tintColor(Color color, double factor) =>
      Color.fromRGBO(tintValue(color.red, factor), tintValue(color.green, factor), tintValue(color.blue, factor), 1);

  static int shadeValue(int value, double factor) => max(0, min(value - (value * factor).round(), 255));

  static Color shadeColor(Color color, double factor) =>
      Color.fromRGBO(shadeValue(color.red, factor), shadeValue(color.green, factor), shadeValue(color.blue, factor), 1);
}

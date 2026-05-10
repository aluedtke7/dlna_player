import 'package:flutter/material.dart';

import 'package:dlna_player/component/color_utils.dart';
import 'package:dlna_player/component/decoration.dart';
import 'package:dlna_player/component/dialog.dart';
import 'package:dlna_player/component/snackbar.dart';

export 'color_utils.dart';
export 'decoration.dart';
export 'dialog.dart';
export 'snackbar.dart';

class Statics {
  static Future<void> showSnackbar(BuildContext ctx, String msg, {bool isError = false}) async =>
      SnackbarHelper.showSnackbar(ctx, msg, isError: isError);

  static Future<void> showErrorSnackbar(BuildContext ctx, dynamic e) => SnackbarHelper.showErrorSnackbar(ctx, e);

  static Future<void> showInfoSnackbar(BuildContext ctx, dynamic e) => SnackbarHelper.showInfoSnackbar(ctx, e);

  static BoxDecoration getSimplePageDecoration() => DecorationBuilder.getSimplePageDecoration();

  static BoxDecoration getGradientPageDecoration() => DecorationBuilder.getGradientPageDecoration();

  static Color getSlideBtnBackgroundLight(BuildContext ctx) => Theme.of(ctx).colorScheme.primary.withAlpha(200);

  static Color getSlideBtnBackgroundDark(BuildContext ctx) => Theme.of(ctx).colorScheme.secondary.withAlpha(200);

  static BoxDecoration getGradientDrawerDecoration(BuildContext ctx) =>
      DecorationBuilder.getGradientDrawerDecoration(ctx);

  static BoxDecoration getSimpleDrawerDecoration(BuildContext ctx) =>
      DecorationBuilder.getSimpleDrawerDecoration(ctx);

  static BoxDecoration getGradientDrawerHeaderDecoration(BuildContext ctx) =>
      DecorationBuilder.getGradientDrawerHeaderDecoration(ctx);

  static BoxDecoration getSimpleDrawerHeaderDecoration(BuildContext ctx) =>
      DecorationBuilder.getSimpleDrawerHeaderDecoration(ctx);

  static Future<String?> showSearchDialog(BuildContext context, String title, String initValue) async =>
      DialogHelper.showSearchDialog(context, title, initValue);

  static Future<String?> showGeniusTokenDialog(BuildContext context, String title, String info, String initVal) async =>
      DialogHelper.showGeniusTokenDialog(context, title, info, initVal);

  static Route createAnimPageRoute(Widget page, {String? name, Object? argument, bool toRight = false}) =>
      DialogHelper.createAnimPageRoute(page, name: name, argument: argument, toRight: toRight);

  static int tintValue(int value, double factor) => ColorUtils.tintValue(value, factor);

  static Color tintColor(Color color, double factor) => ColorUtils.tintColor(color, factor);

  static int shadeValue(int value, double factor) => ColorUtils.shadeValue(value, factor);

  static Color shadeColor(Color color, double factor) => ColorUtils.shadeColor(color, factor);
}

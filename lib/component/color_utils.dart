import 'dart:math';

import 'package:flutter/material.dart';

class ColorUtils {
  static int tintValue(int value, double factor) => max(0, min((value + ((255 - value) * factor)).round(), 255));

  static Color tintColor(Color color, double factor) => Color.fromRGBO(
      tintValue(color.r.toInt(), factor), tintValue(color.g.toInt(), factor), tintValue(color.b.toInt(), factor), 1);

  static int shadeValue(int value, double factor) => max(0, min(value - (value * factor).round(), 255));

  static Color shadeColor(Color color, double factor) => Color.fromRGBO(
      shadeValue(color.r.toInt(), factor), shadeValue(color.g.toInt(), factor), shadeValue(color.b.toInt(), factor), 1);
}

import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

ThemeData _enhance(ThemeData base) {
  return base.copyWith(
    cardTheme: CardThemeData(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 2,
      centerTitle: false,
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 18),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8, pressedElevation: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        animationDuration: Duration(milliseconds: 180),
      ),
    ),
    textTheme: base.textTheme.apply(fontFamilyFallback: const ['SF Pro Text', 'Roboto']),
  );
}

var customThemes = [
  AppTheme(
    id: 'light-green',
    description: 'Light green',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    )),
    options: ThemeOptions(
      const Color(0xFFCDE1C8),
      Statics.getSlideBtnBackgroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-blue',
    description: 'Light blue',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    )),
    options: ThemeOptions(
      const Color(0xFFACCAF1),
      Statics.getSlideBtnBackgroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-purple',
    description: 'Light purple',
    data: _enhance(ThemeData(
      useMaterial3: true,
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    )),
    options: ThemeOptions(
      const Color(0xFFC8BFD2),
      Statics.getSlideBtnBackgroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-deep-orange',
    description: 'Light deep orange',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrange.shade700,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    )),
    options: ThemeOptions(
      const Color(0xFFFADFD0),
      Statics.getSlideBtnBackgroundLight,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'light-orange',
    description: 'Light orange',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.orange,
        accentColor: Colors.orange,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    )),
    options: ThemeOptions(
      const Color(0xFFFFF0E0),
      Statics.getSlideBtnBackgroundLight,
      1.1,
      FontWeight.normal,
      Statics.getSimplePageDecoration(),
      Statics.getSimpleDrawerDecoration,
      Statics.getSimpleDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark-orange',
    description: 'Dark orange',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        accentColor: Colors.orange.shade700,
      ),
    )),
    options: ThemeOptions(
      const Color(0xFF473321),
      Statics.getSlideBtnBackgroundDark,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
  AppTheme(
    id: 'dark-cyan',
    description: 'Dark cyan',
    data: _enhance(ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        accentColor: Colors.cyan.shade700,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 50, 50, 50)),
    )),
    options: ThemeOptions(
      const Color(0xFF0B535E),
      Statics.getSlideBtnBackgroundDark,
      1.4,
      FontWeight.bold,
      Statics.getGradientPageDecoration(),
      Statics.getGradientDrawerDecoration,
      Statics.getGradientDrawerHeaderDecoration,
    ),
  ),
];

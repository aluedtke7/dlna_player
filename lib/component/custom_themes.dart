import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:flutter/material.dart';
import 'package:theme_provider/theme_provider.dart';

var customThemes = [
  AppTheme(
    id: 'light-green',
    description: 'Light green',
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepOrange.shade700,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.orange,
        accentColor: Colors.orange,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 240, 240, 240)),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        accentColor: Colors.orange.shade700,
      ),
    ),
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
    data: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSwatch(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        accentColor: Colors.cyan.shade700,
      ),
      dialogTheme: DialogThemeData(backgroundColor: const Color.fromARGB(255, 50, 50, 50)),
    ),
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

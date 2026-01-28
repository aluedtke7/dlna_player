import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hid_listener/hid_listener.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:window_manager/window_manager.dart';

import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/custom_themes.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/window_settings.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/service/mpris_service.dart';
import 'package:dlna_player/specific_localization_delegate.dart';
import 'package:dlna_player/view/content_page.dart';
import 'package:dlna_player/view/start_page.dart';
import 'package:dlna_player/view/server_page.dart';

const appName = 'DLNA Player';
Timer? saveSettingsTimer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    await windowManager.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final maximized = prefs.getBool(PrefKeys.windowSettingsMaximizedPrefsKey) ?? false;
    final ws = prefs.getString(PrefKeys.windowSettingsPrefsKey) ?? '{}';
    var windowSettings = WindowSettings.fromJson(jsonDecode(ws));
    windowManager.waitUntilReadyToShow(null, () async {
      await windowManager.show();
      await windowManager.focus();
      if (windowSettings.sizeX > 0 && windowSettings.sizeY > 0) {
        windowManager.setPosition(Offset(windowSettings.posX, windowSettings.posY));
        windowManager.setSize(Size(windowSettings.sizeX, windowSettings.sizeY));
      }
      if (maximized) {
        windowManager.maximize();
      }
    });
  }
  runApp(const ProviderScope(child: PlayerApp()));
}

class PlayerApp extends ConsumerStatefulWidget {
  const PlayerApp({super.key});

  @override
  ConsumerState<PlayerApp> createState() => _PlayerAppState();
}

class _PlayerAppState extends ConsumerState<PlayerApp> with WindowListener {
  late SpecificLocalizationDelegate _localeOverrideDelegate;
  MPRISService? _mprisService;

  @override
  void initState() {
    super.initState();
    timeDilation = 1.5;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      windowManager.addListener(this);

      // Initialize hid_listener for X11/macOS/Windows (but not Linux)
      if (!Platform.isLinux) {
        if (!getListenerBackend()!.initialize()) {
          debugPrint('Failed to initialize HID listener backend');
        }
        getListenerBackend()!.addKeyboardListener(listener);
      }

      // Also initialize MPRIS for Linux (works on both X11 and Wayland)
      if (Platform.isLinux) {
        _initializeMPRIS();
      }
    }
    final String initialLanguage;
    if (kIsWeb) {
      initialLanguage = PlatformDispatcher.instance.locale.languageCode;
    } else {
      initialLanguage = Platform.localeName.substring(0, 2);
    }
    _localeOverrideDelegate = SpecificLocalizationDelegate(Locale(initialLanguage));
    Intl.defaultLocale = initialLanguage;

    /// Let's save a pointer to this method, should the user wants to change its language
    /// We would then call: applic.onLocaleChanged(new Locale('en',''));
    APPLIC().onLocaleChanged = onLocaleChange;
    loadSavedList();
  }

  Future<void> _initializeMPRIS() async {
    _mprisService = MPRISService(
      onPlayPause: () {
        debugPrint('MPRIS: Play/Pause triggered');
        ref.read(playingProvider.notifier).playPauseTrack();
      },
      onNext: () {
        debugPrint('MPRIS: Next triggered');
        ref.read(playingProvider.notifier).playNextTrack();
      },
      onPrevious: () {
        debugPrint('MPRIS: Previous triggered');
        ref.read(playingProvider.notifier).playPreviousTrack();
      },
    );
    await _mprisService!.initialize('DLNAPlayer');
  }

  @override
  void dispose() {
    if (Platform.isMacOS || Platform.isWindows) {
      windowManager.removeListener(this);
    }
    _mprisService?.dispose();
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      saveSettingsTimer?.cancel();
      saveSettingsTimer = Timer(const Duration(seconds: 5), () async {
        final prefs = await SharedPreferences.getInstance();
        final maximized = await windowManager.isMaximized();
        prefs.setBool(PrefKeys.windowSettingsMaximizedPrefsKey, maximized);
        if (!maximized) {
          final position = await windowManager.getPosition();
          final size = await windowManager.getSize();
          final ws = WindowSettings(
            position.dx,
            position.dy,
            size.width,
            size.height,
          );
          final s = jsonEncode(ws.toJson());
          prefs.setString(PrefKeys.windowSettingsPrefsKey, s);
        }
        debugPrint('saveSettingsTimer');
      });
    }
  }

  Future<void> loadSavedList() async {
    final prefs = await SharedPreferences.getInstance();
    final lruList = prefs.getStringList(PrefKeys.lruListPrefsKey) ?? [];
    ref.read(lruListProvider).list.addAll(lruList);
  }

  void listener(KeyEvent event) {
    if (event is KeyUpEvent) {
      // debugPrint('logicalKey ${event.logicalKey}');
      if (event.logicalKey == LogicalKeyboardKey.mediaFastForward ||
          event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
        debugPrint('HID next track');
        ref.read(playingProvider.notifier).playNextTrack();
      } else if (event.logicalKey == LogicalKeyboardKey.mediaRewind ||
          event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
        debugPrint('HID prev track');
        ref.read(playingProvider.notifier).playPreviousTrack();
      } else if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
          event.logicalKey == LogicalKeyboardKey.mediaPlay) {
        debugPrint('HID play pause');
        ref.read(playingProvider.notifier).playPauseTrack();
      }
    }
  }

  void onLocaleChange(Locale locale) {
    setState(() {
      _localeOverrideDelegate = SpecificLocalizationDelegate(locale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      onThemeChanged: (oldTheme, newTheme) => debugPrint('Theme: ${newTheme.id}'),
      loadThemeOnInit: true,
      saveThemesOnChange: true,
      themes: customThemes,
      child: ThemeConsumer(
        child: Builder(
          builder: (themeCtx) => MaterialApp(
            title: appName,
            theme: ThemeProvider.themeOf(themeCtx).data,
            localizationsDelegates: [
              _localeOverrideDelegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: APPLIC().supportedLocales(),
            home: const StartPage(title: appName),
            routes: {
              ServerPage.routeName: (context) => const ServerPage(),
              ContentPage.routeName: (context) => const ContentPage(),
            },
          ),
        ),
      ),
    );
  }
}

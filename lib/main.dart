import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:dlna_player/application.dart';
import 'package:dlna_player/component/custom_themes.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/model/window_settings.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/service/mpris_service.dart';
import 'package:dlna_player/specific_localization_delegate.dart';
import 'package:dlna_player/view/content_page.dart';
import 'package:dlna_player/view/server_page.dart';
import 'package:dlna_player/view/start_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hid_listener/hid_listener.dart';
import 'package:intl/intl.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';

const appName = 'DLNA Player';
Timer? saveSettingsTimer;

void main() async {
  // Catch global errors to prevent crashes from just_audio/media_kit issues
  await runZonedGuarded(
    () async {
      await _runApp();
    },
    (error, stack) {
      debugPrint('Global error caught: $error');
    },
  );
}

Future<void> _runApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize just_audio_media_kit for Linux audio support
  JustAudioMediaKit.ensureInitialized();

  // Initialize AudioService for background playback
  final handler = DlnaAudioHandler();
  audioHandler = await AudioService.init(
    builder: () => handler,
    config: AudioServiceConfig(
      androidNotificationChannelId: 'dlna_player_channel',
      androidNotificationChannelName: 'DLNA Player',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidStopForegroundOnPause: true,
    ),
  );

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    final prefs = await SharedPreferences.getInstance();
    final maximized =
        prefs.getBool(PrefKeys.windowSettingsMaximizedPrefsKey) ?? false;
    final ws = prefs.getString(PrefKeys.windowSettingsPrefsKey) ?? '{}';
    final windowSettings = WindowSettings.fromJson(jsonDecode(ws));
    final window = WindowManager.instance.getCurrent();
    if (window != null) {
      window.show();
      window.focus();
      if (windowSettings.sizeX > 0 && windowSettings.sizeY > 0) {
        window.setPosition(windowSettings.posX, windowSettings.posY);
        window.setSize(windowSettings.sizeX, windowSettings.sizeY);
      }
      if (maximized) {
        window.maximize();
      }
    }
  }
  runApp(const ProviderScope(child: PlayerApp()));
}

class PlayerApp extends ConsumerStatefulWidget {
  const PlayerApp({super.key});

  @override
  ConsumerState<PlayerApp> createState() => _PlayerAppState();
}

class _PlayerAppState extends ConsumerState<PlayerApp> {
  late SpecificLocalizationDelegate _localeOverrideDelegate;
  MPRISService? _mprisService;
  Timer? _windowPollTimer;
  Offset? _lastWindowPosition;
  Size? _lastWindowSize;
  bool? _lastWindowMaximized;

  @override
  void initState() {
    super.initState();
    timeDilation = 1.5;
    if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
      _startWindowPolling();

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
      final localeName = Platform.localeName;
      initialLanguage =
          localeName.length >= 2 ? localeName.substring(0, 2) : 'en';
    }
    _localeOverrideDelegate = SpecificLocalizationDelegate(
      Locale(initialLanguage),
    );
    Intl.defaultLocale = initialLanguage;

    /// Let's save a pointer to this method, should the user wants to change its language
    /// We would then call: applic.onLocaleChanged(new Locale('en',''));
    APPLIC().onLocaleChanged = onLocaleChange;
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

  void _startWindowPolling() {
    // nativeapi 0.1.1 has stubbed event dispatch on macOS (WindowMovedEvent /
    // WindowResizedEvent never fire — the OnWindowEvent calls in the Objective-C
    // delegate are commented out). The synchronous window properties work fine
    // on all platforms, so we poll them and debounce the save through
    // _scheduleSaveWindowSettings().
    _windowPollTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      final window = WindowManager.instance.getCurrent();
      if (window == null) return;
      final pos = window.position;
      final size = window.size;
      final maxed = window.isMaximized;
      final changed = _lastWindowPosition != null &&
          (pos != _lastWindowPosition ||
              size != _lastWindowSize ||
              maxed != _lastWindowMaximized);
      _lastWindowPosition = pos;
      _lastWindowSize = size;
      _lastWindowMaximized = maxed;
      if (changed) {
        _scheduleSaveWindowSettings();
      }
    });
  }

  void _scheduleSaveWindowSettings() {
    saveSettingsTimer?.cancel();
    saveSettingsTimer = Timer(const Duration(seconds: 5), () async {
      final window = WindowManager.instance.getCurrent();
      if (window == null) return;
      final prefs = await SharedPreferences.getInstance();
      final maximized = window.isMaximized;
      prefs.setBool(PrefKeys.windowSettingsMaximizedPrefsKey, maximized);
      if (!maximized) {
        final position = window.position;
        final size = window.size;
        final ws = WindowSettings(
          position.dx,
          position.dy,
          size.width,
          size.height,
        );
        prefs.setString(PrefKeys.windowSettingsPrefsKey, jsonEncode(ws.toJson()));
      }
      debugPrint('saveSettingsTimer');
    });
  }

  @override
  void dispose() {
    _windowPollTimer?.cancel();
    _mprisService?.dispose();
    super.dispose();
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
      onThemeChanged:
          (oldTheme, newTheme) => debugPrint('Theme: ${newTheme.id}'),
      loadThemeOnInit: true,
      saveThemesOnChange: true,
      themes: customThemes,
      child: ThemeConsumer(
        child: Builder(
          builder:
              (themeCtx) => MaterialApp(
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

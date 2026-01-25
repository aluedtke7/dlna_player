import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';

class MPRISService {
  DBusClient? _client;
  final Function()? onPlayPause;
  final Function()? onNext;
  final Function()? onPrevious;

  MPRISService({
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
  });

  Future<void> initialize(String appName) async {
    if (!Platform.isLinux) return;

    try {
      _client = DBusClient.session();
      final busName = 'org.mpris.MediaPlayer2.$appName';

      // Request bus name
      await _client!.requestName(busName);

      // Register the MPRIS object
      final mprisObject = MPRISObject(
        onPlayPause: onPlayPause,
        onNext: onNext,
        onPrevious: onPrevious,
        appName: appName,
      );

      await _client!.registerObject(mprisObject);

      debugPrint('MPRIS service initialized successfully as $busName');
    } catch (e) {
      debugPrint('Failed to initialize MPRIS service: $e');
    }
  }

  Future<void> dispose() async {
    await _client?.close();
  }
}

class MPRISObject extends DBusObject {
  final Function()? onPlayPause;
  final Function()? onNext;
  final Function()? onPrevious;
  final String appName;

  MPRISObject({
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    required this.appName,
  }) : super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2',
        methods: [
          DBusIntrospectMethod('Raise'),
          DBusIntrospectMethod('Quit'),
        ],
        properties: [
          DBusIntrospectProperty('CanQuit', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanRaise', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('HasTrackList', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Identity', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedUriSchemes', DBusSignature('as'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedMimeTypes', DBusSignature('as'), access: DBusPropertyAccess.read),
        ],
      ),
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2.Player',
        methods: [
          DBusIntrospectMethod('PlayPause'),
          DBusIntrospectMethod('Next'),
          DBusIntrospectMethod('Previous'),
          DBusIntrospectMethod('Stop'),
          DBusIntrospectMethod('Play'),
          DBusIntrospectMethod('Pause'),
        ],
        properties: [
          DBusIntrospectProperty('PlaybackStatus', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoNext', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoPrevious', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPlay', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPause', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanSeek', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanControl', DBusSignature('b'), access: DBusPropertyAccess.read),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.mpris.MediaPlayer2') {
      switch (methodCall.name) {
        case 'Raise':
          debugPrint('MPRIS: Raise called');
          return DBusMethodSuccessResponse();
        case 'Quit':
          debugPrint('MPRIS: Quit called');
          return DBusMethodSuccessResponse();
      }
    } else if (methodCall.interface == 'org.mpris.MediaPlayer2.Player') {
      switch (methodCall.name) {
        case 'PlayPause':
          debugPrint('MPRIS: PlayPause called');
          onPlayPause?.call();
          return DBusMethodSuccessResponse();
        case 'Next':
          debugPrint('MPRIS: Next called');
          onNext?.call();
          return DBusMethodSuccessResponse();
        case 'Previous':
          debugPrint('MPRIS: Previous called');
          onPrevious?.call();
          return DBusMethodSuccessResponse();
        case 'Stop':
          debugPrint('MPRIS: Stop called');
          return DBusMethodSuccessResponse();
        case 'Play':
          debugPrint('MPRIS: Play called');
          return DBusMethodSuccessResponse();
        case 'Pause':
          debugPrint('MPRIS: Pause called');
          return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.mpris.MediaPlayer2') {
      switch (name) {
        case 'CanQuit':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanRaise':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'HasTrackList':
          return DBusGetPropertyResponse(DBusBoolean(false));
        case 'Identity':
          return DBusGetPropertyResponse(DBusString(appName));
        case 'SupportedUriSchemes':
          return DBusGetPropertyResponse(DBusArray.string([]));
        case 'SupportedMimeTypes':
          return DBusGetPropertyResponse(DBusArray.string([]));
      }
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      switch (name) {
        case 'PlaybackStatus':
          return DBusGetPropertyResponse(DBusString('Playing'));
        case 'CanGoNext':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanGoPrevious':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanPlay':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanPause':
          return DBusGetPropertyResponse(DBusBoolean(true));
        case 'CanSeek':
          return DBusGetPropertyResponse(DBusBoolean(false));
        case 'CanControl':
          return DBusGetPropertyResponse(DBusBoolean(true));
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }

  @override
  Future<DBusMethodResponse> setProperty(String interface, String name, DBusValue value) async {
    return DBusMethodErrorResponse.propertyReadOnly();
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (interface == 'org.mpris.MediaPlayer2') {
      return DBusGetAllPropertiesResponse({
        'CanQuit': DBusBoolean(true),
        'CanRaise': DBusBoolean(true),
        'HasTrackList': DBusBoolean(false),
        'Identity': DBusString(appName),
        'SupportedUriSchemes': DBusArray.string([]),
        'SupportedMimeTypes': DBusArray.string([]),
      });
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      return DBusGetAllPropertiesResponse({
        'PlaybackStatus': DBusString('Playing'),
        'CanGoNext': DBusBoolean(true),
        'CanGoPrevious': DBusBoolean(true),
        'CanPlay': DBusBoolean(true),
        'CanPause': DBusBoolean(true),
        'CanSeek': DBusBoolean(false),
        'CanControl': DBusBoolean(true),
      });
    }
    return DBusMethodErrorResponse.unknownInterface();
  }
}

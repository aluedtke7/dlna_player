import 'package:dlna_player/component/app_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theme_provider/theme_provider.dart';
import 'package:upnp2/upnp.dart' as upnp;

import 'package:dlna_player/component/card/device_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/keyboard_scaffold.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/model/pref_keys.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/view/server_page.dart';

class StartPage extends ConsumerStatefulWidget {
  const StartPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<StartPage> createState() => _StartPageState();
}

class _StartPageState extends ConsumerState<StartPage> {
  List<upnp.Device> devices = [];
  List<upnp.Device> lastDevices = [];
  var searching = false;
  final textNode = FocusNode();

  @override
  void dispose() {
    textNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreviousServer() async {
    setState(() {
      lastDevices = [];
    });
    final prefs = await SharedPreferences.getInstance();
    final lastServerList = prefs.getStringList(PrefKeys.lastUsedServerUrlPrefsKey) ?? [];
    ref.read(lastServerListProvider).list.addAll(lastServerList);

    upnp.DiscoveredClient? dc;
    for (var serverUrl in lastServerList) {
      try {
        dc = upnp.DiscoveredClient();
        dc.location = serverUrl;
        final device = await dc.getDevice();
        if (device == null) {
          return;
        }
        Uri location = Uri.parse(dc.location!);
        // debugPrint('Location: ${location.host}');
        final devType = device.deviceType ?? '';
        // debugPrint('Device type: $devType');
        if (devType.toLowerCase().contains('mediaserver')) {
          final deviceExists = lastDevices.any((dev) => dev.urlBase == device.urlBase);
          if (!deviceExists) {
            debugPrint('Found visited ${device.friendlyName} on IP ${location.host}');
            setState(() {
              lastDevices.add(device);
            });
            // final service = await device.getService(device.services.first.id ?? '');
            // if (service != null) {
            //   for (var element in service.actions) {
            //     debugPrint(element.name);
            //   }
            // }
          }
        }
      } catch (e, stack) {
        if (kDebugMode) {
          print('ERROR: $e - ${dc?.location}');
          print(stack);
        }
        if (mounted) {
          Statics.showErrorSnackbar(context, e);
        }
      }
    }
  }

  Future<void> _searchForServer() async {
    setState(() {
      searching = true;
      devices = [];
    });
    final deviceDiscoverer = upnp.DeviceDiscoverer();
    await deviceDiscoverer.start(
      ipv6: false,
      onError: (e) {
        debugPrint('Error on discover: $e');
        if (mounted) {
          Statics.showErrorSnackbar(context, e);
        }
      },
    );
    deviceDiscoverer.quickDiscoverClients(timeout: const Duration(seconds: 15)).listen((client) async {
      try {
        final device = await client.getDevice();
        if (device == null) {
          return;
        }
        final Uri location = Uri.parse(client.location!);
        // debugPrint('Location: ${location.host}');
        final devType = device.deviceType ?? '';
        // debugPrint('Device type: $devType');
        if (devType.toLowerCase().contains('mediaserver')) {
          final deviceExists = devices.any((dev) => dev.urlBase == device.urlBase);
          if (!deviceExists) {
            debugPrint('Found ${device.friendlyName} on IP ${location.host}');
            setState(() {
              devices.add(device);
            });
            // final service = await device.getService(device.services.first.id ?? '');
            // if (service != null) {
            //   for (var element in service.actions) {
            //     debugPrint(element.name);
            //   }
            // }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('ERROR: $e - ${client.location}');
        }
        if (e is! FormatException && mounted) {
          Statics.showErrorSnackbar(context, e);
        }
      }
    }).onDone(() {
      setState(() {
        searching = false;
      });
      if (devices.isEmpty) {
        var ctx = context;
        if (ctx.mounted) {
          Statics.showErrorSnackbar(ctx, i18n(ctx).server_not_found);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadPreviousServer();
    _searchForServer();
  }

  @override
  Widget build(BuildContext context) {
    final trackRef = ref.watch(trackProvider);

    return KeyboardScaffold(
      focusNode: textNode,
      trackRef: trackRef,
      playingNotifier: ref.read(playingProvider.notifier),
      volumeNotifier: ref.read(volumeProvider.notifier),
      title: widget.title,
      drawer: AppDrawer(discoverFunc: _searchForServer),
      child: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  i18n(context).server_visited(lastDevices.length),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                flex: 3,
                child: SizedBox(
                  width: 600,
                  child: ListView.builder(
                    itemBuilder: (ctx, idx) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(Statics.createAnimPageRoute(const ServerPage(), argument: lastDevices[idx]));
                        },
                        child: DeviceCard(device: lastDevices[idx]),
                      );
                    },
                    itemCount: lastDevices.length,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  i18n(context).server_found(devices.length),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(
                  width: 600,
                  child: ListView.builder(
                    itemBuilder: (ctx, idx) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context)
                              .push(Statics.createAnimPageRoute(const ServerPage(), argument: devices[idx]));
                        },
                        child: DeviceCard(device: devices[idx]),
                      );
                    },
                    itemCount: devices.length,
                  ),
                ),
              ),
              if (searching) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(height: 30, width: 30, child: CircularProgressIndicator()),
                ),
                Text(
                  i18n(context).server_search,
                ),
                const SizedBox(
                  height: 50,
                )
              ],
              if (trackRef.title.isNotEmpty)
                PlayerWidget(
                  trackRef.title,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

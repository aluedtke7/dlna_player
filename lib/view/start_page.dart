import 'package:dlna_player/component/app_drawer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upnp2/upnp.dart' as upnp;

import 'package:dlna_player/component/card/device_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/app_scaffold.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/dialog.dart';
import 'package:dlna_player/component/snackbar.dart';
import 'package:dlna_player/component/tile_style.dart';
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

  /// Loads the visited servers that are reachable. Already shown ones are kept,
  /// so reloading after a server visit only adds the new server.
  Future<void> _loadPreviousServer() async {
    final prefs = await SharedPreferences.getInstance();
    final lastServers = ref.read(lastServerListProvider)
      ..setAll(prefs.getStringList(PrefKeys.lastUsedServerUrlPrefsKey) ?? []);
    final lastServerList = List.of(lastServers.list);

    upnp.DiscoveredClient? dc;
    for (var serverUrl in lastServerList) {
      try {
        dc = upnp.DiscoveredClient();
        dc.location = serverUrl;
        final device = await dc.getDevice().timeout(const Duration(seconds: 3));
        if (device == null) {
          continue;
        }
        Uri location = Uri.parse(dc.location!);
        final devType = device.deviceType ?? '';
        if (devType.toLowerCase().contains('mediaserver')) {
          final deviceExists = lastDevices.any((dev) => dev.urlBase == device.urlBase);
          if (!deviceExists && mounted) {
            debugPrint('Found visited ${device.friendlyName} on IP ${location.host}');
            setState(() {
              lastDevices.add(device);
            });
          }
        }
      } catch (e, stack) {
        if (kDebugMode) {
          print('ERROR: $e - ${dc?.location}');
          print(stack);
        }
        if (mounted) {
          SnackbarHelper.showErrorSnackbar(context, e);
        }
      }
    }
  }

  Future<void> _searchForServer() async {
    if (searching) return;
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
          SnackbarHelper.showErrorSnackbar(context, e);
        }
      },
    );
    deviceDiscoverer.quickDiscoverClients(timeout: const Duration(seconds: 15)).listen((client) async {
      try {
        final device = await client.getDevice().timeout(const Duration(seconds: 3));
        if (device == null) {
          return;
        }
        final Uri location = Uri.parse(client.location!);
        final devType = device.deviceType ?? '';
        if (devType.toLowerCase().contains('mediaserver')) {
          final deviceExists = devices.any((dev) => dev.urlBase == device.urlBase);
          if (!deviceExists) {
            debugPrint('Found ${device.friendlyName} on IP ${location.host}');
            setState(() {
              devices.add(device);
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('ERROR: $e - ${client.location}');
        }
        if (e is! FormatException && mounted) {
          SnackbarHelper.showErrorSnackbar(context, e);
        }
      }
    }).onDone(() {
      if (!mounted) return;
      setState(() {
        searching = false;
      });
      if (devices.isEmpty) {
        var ctx = context;
        if (ctx.mounted) {
          SnackbarHelper.showErrorSnackbar(ctx, i18n(ctx).server_not_found);
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

  void _openServer(upnp.Device device) {
    Navigator.of(context).push(DialogHelper.createAnimPageRoute(const ServerPage(), argument: device)).then((_) {
      // the visited server is now part of the stored list
      if (mounted) _loadPreviousServer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackRef = ref.watch(trackProvider);
    final wide = MediaQuery.sizeOf(context).width >= 600;

    return AppScaffold(
      title: widget.title,
      drawer: AppDrawer(discoverFunc: _searchForServer),
      actions: [
        if (wide)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(
              onPressed: searching ? null : _searchForServer,
              icon: const Icon(Icons.refresh),
              label: Text(i18n(context).start_search_again),
            ),
          )
        else
          IconButton(
            onPressed: searching ? null : _searchForServer,
            icon: const Icon(Icons.refresh),
            tooltip: i18n(context).start_search_again,
          ),
      ],
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16, vertical: wide ? 24 : 8),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lastDevices.isNotEmpty) ...[
                          _SectionHeader(title: i18n(context).start_recent, count: lastDevices.length),
                          _DeviceGrid(devices: lastDevices, onTap: _openServer),
                          const SizedBox(height: 28),
                        ],
                        _SectionHeader(title: i18n(context).start_found, count: devices.length, busy: searching),
                        if (searching && devices.isEmpty)
                          Text(i18n(context).server_search, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        _DeviceGrid(devices: devices, onTap: _openServer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (trackRef.title.isNotEmpty) PlayerWidget(trackRef.title),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count, this.busy = false});

  final String title;
  final int count;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Flexible(child: Text(title, style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Container(
            constraints: const BoxConstraints(minWidth: 24),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: TileStyle.accentSoft(cs), borderRadius: BorderRadius.circular(12)),
            child: Text('$count', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          if (busy) ...[const Spacer(), const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.5))],
        ],
      ),
    );
  }
}

/// Server cards, two per row on wide screens.
class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({required this.devices, required this.onTap});

  final List<upnp.Device> devices;
  final void Function(upnp.Device) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final device in devices) SizedBox(width: width, child: DeviceCard(device: device, onTap: () => onTap(device)))],
        );
      },
    );
  }
}

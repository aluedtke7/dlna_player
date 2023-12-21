import 'package:dlna_player/component/theme_options.dart';
import 'package:dlna_player/component/topic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:theme_provider/theme_provider.dart';

import 'package:upnp2/upnp.dart';

import 'package:dlna_player/component/progress_card.dart';
import 'package:dlna_player/model/content_arguments.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/model/content_container.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/service/dlna_service.dart';
import 'package:dlna_player/view/content_page.dart';

class ServerPage extends ConsumerStatefulWidget {
  const ServerPage({super.key});

  static const routeName = '/server';

  @override
  ConsumerState<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends ConsumerState<ServerPage> {
  List<ContentContainer> cdcs = [];
  var loading = false;
  var index = -1;

  Future<List<ContentContainer>> findContentContainer(
      List<ServiceDescription> serviceList) async {
    List<ContentContainer> cdcs = [];
    for (var svc in serviceList) {
      final service = await svc.getService();
      if (service != null &&
          service.type != null &&
          service.type!.contains('ContentDirectory')) {
        DlnaService.directoryService = service;
        for (var action in service.actions) {
          if (action.name == 'Browse') {
            DlnaService.browseAction = action;
            final browseDoc = await DlnaService.browse('0', maxCount: 0);
            for (var node in browseDoc.children) {
              for (var el in node.children) {
                if (el.attributes.isNotEmpty) {
                  final id = el.attributes
                      .firstWhere((el) => el.name.toString() == 'id')
                      .value;
                  final count = int.tryParse(el.attributes
                          .firstWhere(
                              (el) => el.name.toString() == 'childCount')
                          .value) ??
                      0;
                  final t = el.children[0];
                  final String title = t.firstChild?.value ?? '';
                  cdcs.add(
                      ContentContainer(id: id, title: title, count: count));
                }
              }
            }
            break;
          }
        }
        // listServiceActions(service);
        break;
      }
    }
    return cdcs;
  }

  void listServiceActions(Service service) {
    debugPrint('  Type: ${service.type}');
    debugPrint('  ID: ${service.id}');
    debugPrint('  Control URL: ${service.controlUrl}');
    debugPrint('');
    if (service.actions.isNotEmpty) {
      debugPrint('  - Actions:');
    }
    for (var action in service.actions) {
      debugPrint('    - Name: ${action.name}');
      debugPrint(
          "    - Arguments: ${action.arguments.where((it) => it.direction == "in").map((it) => it.name).toList()}");
      debugPrint(
          "    - Results: ${action.arguments.where((it) => it.direction == "out").map((it) => it.name).toList()}");
      debugPrint('');
    }
    if (service.stateVariables.isNotEmpty) {
      debugPrint('  - State Variables:');
    } else {
      debugPrint('');
    }
    for (var variable in service.stateVariables) {
      debugPrint('    - Name: ${variable.name}');
      debugPrint('    - Data Type: ${variable.dataType}');
      if (variable.defaultValue != null) {
        debugPrint('    - Default Value: ${variable.defaultValue}');
      }
      debugPrint('');
    }
    if (service.actions.isEmpty) {
      debugPrint('');
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = ModalRoute.of(context)!.settings.arguments as Device;
    final trackRef = ref.watch(trackProvider);

    // debugPrint('Device url: ${device.url}');

    ref.read(lastServerListProvider).add(device.url ?? '');
    if (cdcs.isEmpty) {
      findContentContainer(device.services).then((value) {
        setState(() {
          cdcs = value;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          device.friendlyName ?? '',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      body: Container(
        decoration: ThemeProvider.optionsOf<ThemeOptions>(context).pageDecoration,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 350,
                    mainAxisExtent: 120,
                    childAspectRatio: 3,
                  ),
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: () {
                          // debugPrint('Server_page: Loading... $idx');
                          setState(() {
                            loading = true;
                            index = idx;
                          });
                          DlnaService.browseAll(cdcs[idx].id).then((value) {
                            final args = ContentArguments('', value);
                            Navigator.pushNamed(context, ContentPage.routeName,
                                arguments: args);
                            // debugPrint('Server_page: end Loading... $idx');
                            setState(() {
                              loading = false;
                              index = -1;
                            });
                          });
                        },
                        child: loading && index == idx
                            ? ProgressCard(title: cdcs[idx].title)
                            : SizedBox(
                                width: 300,
                                child: TopicCard(topic: cdcs[idx]),
                              ),
                      ),
                    );
                  },
                  itemCount: cdcs.length,
                ),
              ),
            ),
            if (trackRef.title.isNotEmpty)
              PlayerWidget(
                trackRef.title,
              ),
          ],
        ),
      ),
    );
  }
}

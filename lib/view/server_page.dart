import 'package:async/async.dart';
import 'package:dlna_player/component/app_scaffold.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/card/progress_card.dart';
import 'package:dlna_player/component/dialog.dart';
import 'package:dlna_player/component/snackbar.dart';
import 'package:dlna_player/component/card/topic_card.dart';
import 'package:dlna_player/model/content_arguments.dart';
import 'package:dlna_player/model/content_container.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/provider/prefs_provider.dart';
import 'package:dlna_player/service/dlna_service.dart';
import 'package:dlna_player/view/content_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:upnp2/upnp.dart';

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
  final textNode = FocusNode();
  RestartableTimer? timer;
  var initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final device = ModalRoute.of(context)!.settings.arguments as Device;
    ref.read(lastServerListProvider).add(device.url ?? '');
    findContentContainer(device.services).then((value) {
      if (mounted) {
        setState(() {
          cdcs = value;
        });
      }
    });
  }

  @override
  void dispose() {
    textNode.dispose();
    super.dispose();
  }

  Future<List<ContentContainer>> findContentContainer(List<ServiceDescription> serviceList) async {
    List<ContentContainer> cdcs = [];
    for (var svc in serviceList) {
      final service = await svc.getService();
      if (service != null && service.type != null && service.type!.contains('ContentDirectory')) {
        DlnaService.directoryService = service;
        for (var action in service.actions) {
          if (action.name == 'Browse') {
            DlnaService.browseAction = action;
            try {
              final browseDoc = await DlnaService.browse('0', maxCount: 0);
              for (var node in browseDoc.children) {
                for (var el in node.children) {
                  if (el.attributes.isNotEmpty) {
                    final id = el.attributes.firstWhere((el) => el.name.toString() == 'id').value;
                    final count = int.tryParse(el.attributes.firstWhere((el) => el.name.toString() == 'childCount').value) ?? 0;
                    final t = el.children[0];
                    final String title = t.firstChild?.value ?? '';
                    cdcs.add(ContentContainer(id: id, title: title, count: count));
                  }
                }
              }
              break;
            } catch (e) {
              if (mounted) {
                if (timer == null || !timer!.isActive) {
                  SnackbarHelper.showErrorSnackbar(context, e);
                }
                timer = RestartableTimer(Duration(seconds: 4), () {});
              }
            }
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
      debugPrint("    - Arguments: ${action.arguments.where((it) => it.direction == "in").map((it) => it.name).toList()}");
      debugPrint("    - Results: ${action.arguments.where((it) => it.direction == "out").map((it) => it.name).toList()}");
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

    final wide = MediaQuery.sizeOf(context).width >= 600;

    void openTopic(int idx) {
      if (loading) return;
      setState(() {
        loading = true;
        index = idx;
      });
      DlnaService.browseAll(cdcs[idx].id)
          .then((value) {
            final args = ContentArguments('', value);
            if (context.mounted) {
              Navigator.of(context).push(DialogHelper.createAnimPageRoute(const ContentPage(), argument: args));
            }
          })
          .catchError((Object e) {
            if (context.mounted) {
              SnackbarHelper.showErrorSnackbar(context, e);
            }
          })
          .whenComplete(() {
            if (mounted) {
              setState(() {
                loading = false;
                index = -1;
              });
            }
          });
    }

    return AppScaffold(
      title: device.friendlyName ?? '',
      subtitle: Uri.parse(device.urlBase ?? '').origin,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 16, vertical: wide ? 24 : 12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: wide ? 148 : 128,
                crossAxisSpacing: wide ? 16 : 12,
                mainAxisSpacing: wide ? 16 : 12,
              ),
              itemBuilder: (context, idx) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  // Fill the grid cell so all tiles get the same size.
                  layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
                  child:
                      loading && index == idx
                          ? ProgressCard(title: cdcs[idx].title)
                          : TopicCard(topic: cdcs[idx], onTap: () => openTopic(idx)),
                );
              },
              itemCount: cdcs.length,
            ),
          ),
          if (trackRef.title.isNotEmpty) PlayerWidget(trackRef.title),
        ],
      ),
    );
  }
}

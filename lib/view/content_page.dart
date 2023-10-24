import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dlna_player/component/album_card.dart';
import 'package:dlna_player/component/container_card.dart';
import 'package:dlna_player/component/i18n_util.dart';
import 'package:dlna_player/component/player_widget.dart';
import 'package:dlna_player/component/progress_card.dart';
import 'package:dlna_player/component/statics.dart';
import 'package:dlna_player/component/track_card.dart';
import 'package:dlna_player/model/content_arguments.dart';
import 'package:dlna_player/model/content_class.dart';
import 'package:dlna_player/model/raw_content.dart';
import 'package:dlna_player/provider/player_provider.dart';
import 'package:dlna_player/service/dlna_service.dart';

class ContentPage extends ConsumerStatefulWidget {
  const ContentPage({Key? key}) : super(key: key);
  static const routeName = '/container';

  @override
  ConsumerState<ContentPage> createState() => _ContentPageState();
}

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

class ClearSearchIntent extends Intent {
  const ClearSearchIntent();
}

class _ContentPageState extends ConsumerState<ContentPage> {
  var searchTerm = '';
  var currentTrackTitle = '';
  var showPlayerWidget = true;
  var searching = false;
  var searchIdx = -1;

  String buildTitle(String parent, String title) {
    return (parent.isNotEmpty ? '$parent - ' : '') + title;
  }

  @override
  Widget build(BuildContext context) {
    ContentClass type;
    final trackRef = ref.watch(trackProvider);
    final argument = ModalRoute.of(context)!.settings.arguments as ContentArguments;
    if (argument.content.isEmpty) {
      type = ContentClass.none;
    } else {
      type = argument.content.first.classType;
      if (type == ContentClass.none && argument.content.length > 1) {
        type = argument.content[1].classType;
      }
    }
    final typeName = i18n(context).content_class(type.toString());
    // build filtered list based on search term
    final List<RawContent> selItems;
    final double mainAxisExtend;
    switch (type) {
      case ContentClass.album:
        selItems = argument.content
            .where((el) =>
                el.title.toLowerCase().contains(searchTerm) ||
                el.artist.toLowerCase().contains(searchTerm))
            .toList();
        mainAxisExtend = 100;
        break;
      case ContentClass.artist:
        selItems = argument.content
            .where((el) =>
                el.title.toLowerCase().contains(searchTerm) ||
                el.genre.toLowerCase().contains(searchTerm))
            .toList();
        mainAxisExtend = 90;
        break;
      case ContentClass.genre:
      case ContentClass.playlist:
        selItems =
            argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 70;
        break;
      case ContentClass.folder:
        selItems =
            argument.content.where((el) => el.title.toLowerCase().contains(searchTerm)).toList();
        mainAxisExtend = 85;
        break;
      case ContentClass.track:
        selItems = argument.content
            .where((el) =>
                el.title.toLowerCase().contains(searchTerm) ||
                el.artist.toLowerCase().contains(searchTerm) ||
                el.album.toLowerCase().contains(searchTerm))
            .toList();
        mainAxisExtend = 100;
        break;
      default:
        selItems = argument.content;
        mainAxisExtend = 120;
    }

    void openSearchDialog() {
      Statics.showSearchDialog(context, i18n(context).content_search_for, searchTerm).then((value) {
        if (value != null) {
          setState(() {
            searchTerm = value.toLowerCase();
          });
        }
      });
    }

    void clearSearch() {
      if (searchTerm.isNotEmpty) {
        setState(() {
          searchTerm = '';
        });
      }
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const OpenSearchIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX):
            const ClearSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(
            onInvoke: (intent) => openSearchDialog(),
          ),
          ClearSearchIntent: CallbackAction<ClearSearchIntent>(
            onInvoke: (intent) => clearSearch(),
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: Text(buildTitle(argument.title, typeName)),
              titleTextStyle: const TextStyle(overflow: TextOverflow.fade, fontSize: 16),
              actions: [
                IconButton(
                  onPressed: openSearchDialog,
                  icon: const Icon(Icons.search),
                  tooltip: i18n(context).com_f3,
                ),
                IconButton(
                  onPressed: searchTerm.isEmpty ? null : clearSearch,
                  icon: const Icon(Icons.clear),
                  tooltip: i18n(context).com_ctrl_x,
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(
                  height: 4,
                ),
                Text(i18n(context).content_selected(selItems.length, argument.content.length,
                    searchTerm.isNotEmpty ? " - $searchTerm" : "")),
                const SizedBox(
                  height: 4,
                ),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisExtent: mainAxisExtend,
                      childAspectRatio: 3,
                    ),
                    itemBuilder: (ctx, idx) {
                      return GestureDetector(
                          onTap: () {
                            if (selItems[idx].classType != ContentClass.track) {
                              // debugPrint('Content_page: Loading... $idx');
                              setState(() {
                                searching = true;
                                searchIdx = idx;
                              });
                              // open another page with content
                              DlnaService.browseAll(selItems[idx].id).then((value) {
                                if (value.isNotEmpty) {
                                  final args =
                                      ContentArguments(buildTitle(argument.title, typeName), value);
                                  Navigator.pushNamed(context, ContentPage.routeName,
                                      arguments: args);
                                }
                                // debugPrint('Content_page: end Loading... $idx');
                                setState(() {
                                  searching = false;
                                  searchIdx = -1;
                                });
                              });
                            } else {
                              // play track
                              if ((selItems[idx].trackUrl ?? '').isNotEmpty) {
                                ref.read(trackProvider.notifier).setTrack(selItems[idx]);
                                var player = ref.read(playerProvider);
                                // make current visible list the playlist and set index
                                ref.read(playlistProvider.notifier).setPlaylist(selItems
                                    .where((element) => element.classType == ContentClass.track)
                                    .toList());
                                ref.read(playlistIndexProvider.notifier).setIndex(idx);
                                player.play(UrlSource(selItems[idx].trackUrl!));
                                ref.read(lruListProvider).add(selItems[idx].id);
                                Statics.showInfoSnackbar(context, i18n(context).com_new_playlist);
                              }
                            }
                          },
                          child: searching && searchIdx == idx
                              ? ProgressCard(title: selItems[idx].title)
                              : selItems[idx].classType == ContentClass.album
                                  ? AlbumCard(container: selItems[idx])
                                  : selItems[idx].classType == ContentClass.track
                                      ? TrackCard(track: selItems[idx])
                                      : ContainerCard(container: selItems[idx]));
                    },
                    itemCount: selItems.length,
                  ),
                ),
                PlayerWidget(
                  trackRef.title,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
